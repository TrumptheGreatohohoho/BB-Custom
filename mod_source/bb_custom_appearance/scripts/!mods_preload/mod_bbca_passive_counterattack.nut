// Prevent Aegis Passive Counterattack from answering attacks that were
// triggered by movement through an enemy zone of control. Vanilla reuses the
// attacker's ordinary attack-of-opportunity skill for both manual attacks and
// movement-triggered attacks, so a short-lived execution context is the
// narrowest reliable discriminator.

if (!("BBCA_PassiveCounterattack" in getroottable()))
{
    ::BBCA_PassiveCounterattack <- {
        MovementAttackDepth = 0,

        function beginMovementAttack()
        {
            ++this.MovementAttackDepth;
        },

        function finishMovementAttack()
        {
            --this.MovementAttackDepth;
            if (this.MovementAttackDepth < 0)
            {
                this.MovementAttackDepth = 0;
            }
        },

        function isMovementAttack()
        {
            return this.MovementAttackDepth > 0;
        }
    };
}

// Hook only the exact actor class where the function is defined. Using
// mods_hookClass here also invokes this callback for every direct child class;
// those child member tables do not contain the inherited function and fail
// during class registration before an existing campaign can be deserialized.
::mods_hookExactClass("entity/tactical/actor", function(o) {
    local bbca_originalOnAttackOfOpportunity = o.onAttackOfOpportunity;
    o.onAttackOfOpportunity = function( _entity, _isOnEnter )
    {
        ::BBCA_PassiveCounterattack.beginMovementAttack();

        try
        {
            local result = bbca_originalOnAttackOfOpportunity.call(this, _entity, _isOnEnter);
            ::BBCA_PassiveCounterattack.finishMovementAttack();
            return result;
        }
        catch (exception)
        {
            ::BBCA_PassiveCounterattack.finishMovementAttack();
            throw exception;
        }
    }
});
