// Raise the Lone Wolf total roster and tactical deployment caps. This remains a
// narrow wrapper: vanilla still controls scenario setup and enemy scaling.

::mods_hookClass("scenarios/world/lone_wolf_scenario", function(o) {
    local bbca_originalCreate = o.create;
    o.create = function()
    {
        bbca_originalCreate.call(this);
        this.m.Description = "[p=c][img]gfx/ui/events/event_35.png[/img][/p][p]You've been traveling alone for a long time, taking part in tourneys and sparring with young nobles. A hedge knight tall as a tree, you never needed anybody for long. Is it true still?\n\n[color=#bcad8c]Lone Wolf:[/color] Start with a single experienced hedge knight and great equipment, but low funds.\n[color=#bcad8c]Elite Few:[/color] Can never have more than 16 men in your roster.\n[color=#bcad8c]Avatar:[/color] If your hedge knight dies, the campaign ends.[/p]";
    }

    local bbca_originalOnInit = o.onInit;
    o.onInit = function()
    {
        bbca_originalOnInit.call(this);
        this.World.Assets.m.BrothersMax = 16;
        this.World.Assets.m.BrothersMaxInCombat = 16;
    }
});
