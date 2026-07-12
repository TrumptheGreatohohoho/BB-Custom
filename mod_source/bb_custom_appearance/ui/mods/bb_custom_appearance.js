"use strict";

(function() {
    if (typeof WorldBreditorScreen === "undefined") {
        console.error("Custom Appearance requires the Breditor screen.");
        return;
    }

    var roles = ["body", "head", "hair", "beard"];
    var roleLabels = {
        body: "Body",
        head: "Head",
        hair: "Hair",
        beard: "Beard"
    };
    var originalCreateDIV = WorldBreditorScreen.prototype.createDIV;
    var originalDestroyDIV = WorldBreditorScreen.prototype.destroyDIV;
    var originalUpdateDetailsPanel = WorldBreditorScreen.prototype.updateDetailsPanel;

    function formatEntryLabel(entry) {
        return entry.ID === "" ? entry.Label : entry.Label + " (" + entry.ID + ")";
    }

    function createOption(entry) {
        return $('<button type="button" class="bbca-menu-option"/>')
            .attr("data-brush-id", entry.ID)
            .text(formatEntryLabel(entry));
    }

    function createSkillOption(entry) {
        return $('<button type="button" class="bbca-menu-option"/>')
            .attr("data-skill-id", entry.ID)
            .text(entry.Label);
    }

    function catalogForRole(catalog, role) {
        var result = [];
        for (var i = 0; i < catalog.length; i++) {
            if (catalog[i].Role === role) {
                result.push(catalog[i]);
            }
        }
        return result;
    }

    function setApplyState(button, state) {
        button.removeClass("bbca-applying bbca-applied bbca-failed");

        if (state === "applying") {
            button.addClass("bbca-applying").text("APPLYING...").prop("disabled", true);
        } else if (state === "applied") {
            button.addClass("bbca-applied").text("APPLIED").prop("disabled", false);
        } else if (state === "failed") {
            button.addClass("bbca-failed").text("FAILED").prop("disabled", false);
        } else {
            button.text("APPLY").prop("disabled", false);
        }
    }

    function setSkillApplyState(button, state, hasSkill) {
        button.removeClass("bbca-applying bbca-applied bbca-failed");

        if (state === "applying") {
            button.addClass("bbca-applying").text("保存中...").prop("disabled", true);
        } else if (state === "applied") {
            button.addClass("bbca-applied").text(hasSkill ? "参数已保存" : "已授予").prop("disabled", false);
        } else if (state === "failed") {
            button.addClass("bbca-failed").text("操作失败").prop("disabled", false);
        } else {
            button.text(hasSkill ? "保存参数" : "授予技能").prop("disabled", false);
        }
    }

    function updatePreview(screen, result) {
        if (result === null || result === undefined || result.Error !== undefined) {
            return;
        }

        if (screen.mData !== null && screen.mData.ID === result.BroId) {
            screen.mData.ImagePath = result.ImagePath;
            screen.mData.BroImage.attr("src", Path.PROCEDURAL + result.ImagePath);
        }

        screen.bbcaUpdateControls(result.Appearance);
    }

    WorldBreditorScreen.prototype.createDIV = function(_parentDiv) {
        originalCreateDIV.call(this, _parentDiv);

        var self = this;
        this.mCustomAppearance = {
            Catalog: [],
            Panel: $('<div class="bbca-panel display-none"/>'),
            Status: $('<div class="bbca-status"/>'),
            Selects: {}
        };

        this.mContainer.append(this.mCustomAppearance.Panel);
        this.mCustomAppearance.Panel.append($('<div class="bbca-title"/>').text("CUSTOM APPEARANCE"));

        for (var i = 0; i < roles.length; i++) {
            var role = roles[i];
            var row = $('<div class="bbca-row"/>');
            var label = $('<div class="bbca-role"/>').text(roleLabels[role]);
            var select = $('<button type="button" class="bbca-select"/>').text("Loading...").prop("disabled", true);
            var selectWrap = $('<div class="bbca-select-wrap"/>');
            var menu = $('<div class="bbca-menu display-none"/>');
            var apply = $('<button type="button" class="bbca-apply"/>').text("APPLY").prop("disabled", true);

            (function(selectedRole, selectedSelect, selectedMenu, selectedApply) {
                selectedSelect.click(function() {
                    if (!selectedSelect.prop("disabled")) {
                        selectedMenu.toggleClass("display-none");
                    }
                });

                selectedApply.click(function() {
                    var selectedControl = self.mCustomAppearance.Selects[selectedRole];
                    if (self.mData === null || selectedControl.Value === null) {
                        return;
                    }

                    setApplyState(selectedApply, "applying");
                    self.mCustomAppearance.Status.text("Applying " + selectedRole + "...");
                    SQ.call(self.mSQHandle, "applyCustomAppearance", {
                        BroId: self.mData.ID,
                        Role: selectedRole,
                        BrushId: selectedControl.Value
                    }, function(result) {
                        if (result !== null && result.Error !== undefined) {
                            setApplyState(selectedApply, "failed");
                            self.mCustomAppearance.Status.text(result.Error);
                            return;
                        }

                        setApplyState(selectedApply, "applied");
                        self.mCustomAppearance.Status.text(selectedRole.toUpperCase() + " applied");
                        updatePreview(self, result);
                    });
                });
            })(role, select, menu, apply);

            row.append(label);
            selectWrap.append(select);
            selectWrap.append(menu);
            row.append(selectWrap);
            row.append(apply);
            this.mCustomAppearance.Panel.append(row);
            this.mCustomAppearance.Selects[role] = {
                Select: select,
                Menu: menu,
                Value: null,
                Apply: apply
            };
        }

        this.mCustomAppearance.Panel.append(this.mCustomAppearance.Status);

        this.mCustomSkills = {
            Catalog: [],
            StateById: {},
            SelectedId: null,
            Panel: $('<div class="bbca-skill-panel display-none"/>'),
            Select: $('<button type="button" class="bbca-select"/>').text("加载中...").prop("disabled", true),
            Menu: $('<div class="bbca-menu display-none"/>'),
            Description: $('<div class="bbca-skill-description"/>'),
            Fields: $('<div class="bbca-skill-fields"/>'),
            Apply: $('<button type="button" class="bbca-apply bbca-skill-apply"/>').prop("disabled", true),
            Status: $('<div class="bbca-status bbca-skill-status"/>'),
            Inputs: {}
        };

        var skillSelectWrap = $('<div class="bbca-select-wrap bbca-skill-select-wrap"/>');
        skillSelectWrap.append(this.mCustomSkills.Select);
        skillSelectWrap.append(this.mCustomSkills.Menu);
        this.mCustomSkills.Panel.append($('<div class="bbca-title bbca-skill-title"/>').text("技能编辑器"));
        this.mCustomSkills.Panel.append($('<div class="bbca-skill-label"/>').text("选择技能"));
        this.mCustomSkills.Panel.append(skillSelectWrap);
        this.mCustomSkills.Panel.append(this.mCustomSkills.Description);
        this.mCustomSkills.Panel.append(this.mCustomSkills.Fields);
        this.mCustomSkills.Panel.append(this.mCustomSkills.Apply);
        this.mCustomSkills.Panel.append(this.mCustomSkills.Status);
        this.mContainer.append(this.mCustomSkills.Panel);

        this.mCustomSkills.Select.click(function() {
            if (!self.mCustomSkills.Select.prop("disabled")) {
                self.mCustomSkills.Menu.toggleClass("display-none");
            }
        });

        this.mCustomSkills.Apply.click(function() {
            self.bbcaApplySelectedSkill();
        });

        SQ.call(this.mSQHandle, "getCustomAppearanceCatalog", null, function(catalog) {
            self.mCustomAppearance.Catalog = catalog || [];
            self.bbcaPopulateControls();
        });

        SQ.call(this.mSQHandle, "getCustomSkillCatalog", null, function(catalog) {
            self.mCustomSkills.Catalog = catalog || [];
            self.bbcaPopulateSkillControls();
        });
    };

    WorldBreditorScreen.prototype.destroyDIV = function() {
        if (this.mCustomAppearance !== undefined && this.mCustomAppearance !== null) {
            this.mCustomAppearance.Panel.remove();
            this.mCustomAppearance = null;
        }
        if (this.mCustomSkills !== undefined && this.mCustomSkills !== null) {
            this.mCustomSkills.Panel.remove();
            this.mCustomSkills = null;
        }
        originalDestroyDIV.call(this);
    };

    WorldBreditorScreen.prototype.updateDetailsPanel = function(_element) {
        originalUpdateDetailsPanel.call(this, _element);

        if (this.mCustomAppearance === null || this.mCustomAppearance === undefined ||
            this.mCustomSkills === null || this.mCustomSkills === undefined) {
            return;
        }

        if (_element === null || _element.length === 0 || this.mData === null) {
            this.mCustomAppearance.Panel.addClass("display-none");
            this.mCustomSkills.Panel.addClass("display-none");
            return;
        }

        this.mCustomAppearance.Panel.removeClass("display-none");
        this.mCustomSkills.Panel.removeClass("display-none");
        this.bbcaPopulateControls();
        this.bbcaPopulateSkillControls();

        var self = this;
        var brotherId = this.mData.ID;
        SQ.call(this.mSQHandle, "getCustomAppearance", { BroId: brotherId }, function(result) {
            if (self.mData !== null && self.mData.ID === brotherId && result !== null) {
                self.bbcaUpdateControls(result.Appearance);
            }
        });
        this.bbcaLoadSkillState(brotherId);
    };

    WorldBreditorScreen.prototype.bbcaPopulateControls = function() {
        if (this.mCustomAppearance === null || this.mCustomAppearance === undefined) {
            return;
        }

        for (var i = 0; i < roles.length; i++) {
            var role = roles[i];
            var control = this.mCustomAppearance.Selects[role];
            var entries = catalogForRole(this.mCustomAppearance.Catalog, role);
            if (role === "beard") {
                entries.unshift({ ID: "", Label: "No beard" });
            }

            control.Menu.empty().addClass("display-none");
            if (entries.length === 0) {
                control.Value = null;
                control.Select.text("No custom " + role + " assets");
                control.Select.prop("disabled", true);
                control.Apply.prop("disabled", true);
                continue;
            }

            for (var j = 0; j < entries.length; j++) {
                (function(entry, selectedControl) {
                    var option = createOption(entry);
                    option.click(function() {
                        selectedControl.Value = entry.ID;
                        selectedControl.Select.text(formatEntryLabel(entry));
                        selectedControl.Menu.addClass("display-none");
                        setApplyState(selectedControl.Apply, "ready");
                    });
                    control.Menu.append(option);
                })(entries[j], control);
            }
            control.Value = entries[0].ID;
            control.Select.text(formatEntryLabel(entries[0]));
            control.Select.prop("disabled", false);
            setApplyState(control.Apply, "ready");
        }
    };

    WorldBreditorScreen.prototype.bbcaUpdateControls = function(appearance) {
        if (appearance === null || appearance === undefined || this.mCustomAppearance === null || this.mCustomAppearance === undefined) {
            return;
        }

        for (var i = 0; i < roles.length; i++) {
            var role = roles[i];
            var control = this.mCustomAppearance.Selects[role];
            var value = appearance[role];
            if (value !== undefined && control.Menu.find('[data-brush-id="' + value + '"]').length !== 0) {
                control.Value = value;
                control.Select.text(control.Menu.find('[data-brush-id="' + value + '"]').text());
            }
        }
    };

    WorldBreditorScreen.prototype.bbcaGetSkillDefinition = function(skillId) {
        if (this.mCustomSkills === null || this.mCustomSkills === undefined) {
            return null;
        }
        for (var i = 0; i < this.mCustomSkills.Catalog.length; i++) {
            if (this.mCustomSkills.Catalog[i].ID === skillId) {
                return this.mCustomSkills.Catalog[i];
            }
        }
        return null;
    };

    WorldBreditorScreen.prototype.bbcaPopulateSkillControls = function() {
        if (this.mCustomSkills === null || this.mCustomSkills === undefined) {
            return;
        }

        var skills = this.mCustomSkills;
        skills.Menu.empty().addClass("display-none");
        if (skills.Catalog.length === 0) {
            skills.SelectedId = null;
            skills.Select.text("暂无可用技能").prop("disabled", true);
            skills.Apply.prop("disabled", true);
            skills.Description.text("技能目录为空。");
            skills.Fields.empty();
            return;
        }

        for (var i = 0; i < skills.Catalog.length; i++) {
            (function(entry) {
                var option = createSkillOption(entry);
                option.click(function() {
                    skills.Menu.addClass("display-none");
                    this.bbcaSelectCustomSkill(entry.ID);
                }.bind(this));
                skills.Menu.append(option);
            }).call(this, skills.Catalog[i]);
        }

        skills.Select.prop("disabled", false);
        if (skills.SelectedId === null || this.bbcaGetSkillDefinition(skills.SelectedId) === null) {
            this.bbcaSelectCustomSkill(skills.Catalog[0].ID);
        } else {
            this.bbcaRenderSelectedSkill();
        }
    };

    WorldBreditorScreen.prototype.bbcaSelectCustomSkill = function(skillId) {
        if (this.mCustomSkills === null || this.mCustomSkills === undefined) {
            return;
        }
        this.mCustomSkills.SelectedId = skillId;
        this.bbcaRenderSelectedSkill();
    };

    WorldBreditorScreen.prototype.bbcaRenderSelectedSkill = function() {
        var skills = this.mCustomSkills;
        var definition = this.bbcaGetSkillDefinition(skills.SelectedId);
        if (definition === null) {
            return;
        }

        var state = skills.StateById[definition.ID];
        var settings = state === undefined ? {} : (state.Settings || {});
        skills.Select.text(definition.Label);
        skills.Description.text(definition.Description);
        skills.Fields.empty();
        skills.Inputs = {};

        for (var i = 0; i < definition.Parameters.length; i++) {
            var parameter = definition.Parameters[i];
            var field = $('<label class="bbca-skill-field"/>');
            var value = settings[parameter.Key] === undefined ? parameter.Default : settings[parameter.Key];
            var input;
            var fieldControl;
            if (parameter.Type === "bool") {
                var isEnabled = value === true || value === "true";
                input = $('<input type="hidden"/>').val(isEnabled ? "true" : "false");
                // Click-to-toggle button (no dropdown menu, so nothing gets clipped
                // by the scrollable fields container on the bottom rows).
                var toggle = $('<button type="button" class="bbca-skill-toggle"/>')
                    .text(isEnabled ? "开启" : "关闭")
                    .addClass(isEnabled ? "bbca-toggle-on" : "bbca-toggle-off");
                var toggleWrap = $('<div class="bbca-skill-toggle-wrap"/>');

                (function(selectedInput, selectedToggle) {
                    selectedToggle.click(function() {
                        var nowEnabled = selectedInput.val() !== "true";
                        selectedInput.val(nowEnabled ? "true" : "false");
                        selectedToggle.text(nowEnabled ? "开启" : "关闭")
                            .toggleClass("bbca-toggle-on", nowEnabled)
                            .toggleClass("bbca-toggle-off", !nowEnabled);
                    });
                })(input, toggle);

                toggleWrap.append(input);
                toggleWrap.append(toggle);
                fieldControl = toggleWrap;
            } else {
                input = $('<input type="text" class="bbca-skill-input"/>')
                    .attr("inputmode", "numeric")
                    .attr("pattern", "[0-9]*")
                    .attr("maxlength", String(parameter.Max).length)
                    .attr("data-min", parameter.Min)
                    .attr("data-max", parameter.Max)
                    .val(value);

                (function(selectedInput) {
                    selectedInput.on("mousedown mouseup click focus", function(event) {
                        event.stopPropagation();
                    });

                    selectedInput.on("focus", function() {
                        var element = this;
                        window.setTimeout(function() {
                            element.select();
                        }, 0);
                    });

                    selectedInput.on("keydown", function(event) {
                        var code = event.which || event.keyCode;
                        var isCtrlCommand = event.ctrlKey === true || event.metaKey === true;
                        var isNumber = (code >= 48 && code <= 57) || (code >= 96 && code <= 105);
                        var isNavigation = code === 8 || code === 9 || code === 13 || code === 27 ||
                            code === 35 || code === 36 || code === 37 || code === 38 ||
                            code === 39 || code === 40 || code === 46;

                        event.stopPropagation();

                        if (isCtrlCommand || isNumber || isNavigation) {
                            return true;
                        }

                        event.preventDefault();
                        return false;
                    });

                    selectedInput.on("input", function() {
                        var raw = String($(this).val());
                        var clean = raw.replace(/[^0-9]/g, "");
                        if (raw !== clean) {
                            $(this).val(clean);
                        }
                    });
                })(input);
                fieldControl = input;
            }
            field.append($('<span/>').text(parameter.Label));
            field.append(fieldControl);
            skills.Fields.append(field);
            skills.Inputs[parameter.Key] = input;
        }

        setSkillApplyState(skills.Apply, "ready", state !== undefined && state.HasSkill === true);
    };

    WorldBreditorScreen.prototype.bbcaLoadSkillState = function(brotherId) {
        if (this.mCustomSkills === null || this.mCustomSkills === undefined) {
            return;
        }

        var self = this;
        this.mCustomSkills.StateById = {};
        this.bbcaRenderSelectedSkill();
        SQ.call(this.mSQHandle, "getCustomSkillState", { BroId: brotherId }, function(result) {
            if (self.mData === null || self.mData.ID !== brotherId || result === null) {
                return;
            }
            if (result.Error !== undefined) {
                self.mCustomSkills.Status.text(result.Error);
                return;
            }

            self.mCustomSkills.StateById = {};
            for (var i = 0; i < result.Skills.length; i++) {
                self.mCustomSkills.StateById[result.Skills[i].ID] = result.Skills[i];
            }
            self.bbcaRenderSelectedSkill();
        });
    };

    WorldBreditorScreen.prototype.bbcaApplySelectedSkill = function() {
        if (this.mCustomSkills === null || this.mCustomSkills === undefined || this.mData === null) {
            return;
        }

        var skills = this.mCustomSkills;
        var definition = this.bbcaGetSkillDefinition(skills.SelectedId);
        if (definition === null) {
            return;
        }

        var settings = {};
        for (var i = 0; i < definition.Parameters.length; i++) {
            var parameter = definition.Parameters[i];
            var raw = skills.Inputs[parameter.Key].val();
            if (parameter.Type === "bool") {
                settings[parameter.Key] = raw === "true";
                continue;
            }
            var value = Number(raw);
            if (!isFinite(value) || Math.floor(value) !== value || value < parameter.Min || value > parameter.Max) {
                skills.Status.text(parameter.Label + " 必须是 " + parameter.Min + " 到 " + parameter.Max + " 的整数。");
                setSkillApplyState(skills.Apply, "failed", false);
                return;
            }
            settings[parameter.Key] = value;
        }
        if (settings.MinRange !== undefined && settings.MaxRange !== undefined && settings.MinRange > settings.MaxRange) {
            skills.Status.text("最小距离不能大于最大距离。");
            setSkillApplyState(skills.Apply, "failed", false);
            return;
        }

        var wasGranted = skills.StateById[definition.ID] !== undefined && skills.StateById[definition.ID].HasSkill === true;
        setSkillApplyState(skills.Apply, "applying", wasGranted);
        skills.Status.text(wasGranted ? "正在保存参数..." : "正在授予技能...");

        var self = this;
        var brotherId = this.mData.ID;
        SQ.call(this.mSQHandle, "applyCustomSkill", {
            BroId: brotherId,
            SkillId: definition.ID,
            Settings: settings
        }, function(result) {
            if (self.mData === null || self.mData.ID !== brotherId || result === null) {
                return;
            }
            if (result.Error !== undefined) {
                skills.Status.text(result.Error);
                setSkillApplyState(skills.Apply, "failed", wasGranted);
                return;
            }

            skills.StateById[result.SkillId] = {
                ID: result.SkillId,
                HasSkill: result.HasSkill,
                Settings: result.Settings
            };
            self.bbcaRenderSelectedSkill();
            setSkillApplyState(skills.Apply, "applied", result.WasAlreadyGranted === true);
            skills.Status.text(result.WasAlreadyGranted === true ? definition.Label + " 参数已保存。" : "已为该角色授予 " + definition.Label + "。");
        });
    };
})();

