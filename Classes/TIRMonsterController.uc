class TIRMonsterController extends MonsterController;

var bool bResetJumpZ;

function Possess(Pawn aPawn) {
    Super.Possess(aPawn);
    
    aPawn.JumpZ = -0.1; //avoid a loud landing sound...
    bResetJumpZ = true;
}

simulated event Tick(float dt) {
    Super.Tick(dt);
    
    if(Role == ROLE_Authority && bResetJumpZ && Pawn.Base != None) {
        Pawn.JumpZ = Pawn.default.JumpZ;
        bResetJumpZ = false;
    }
}

//override to stop monsters from warping to nearby player spawns
function FightEnemy(bool bCanCharge) {
    local vector X,Y,Z;
    local float enemyDist;
    local float AdjustedCombatStyle, Aggression;
    local bool bFarAway, bOldForcedCharge;

    if ( (Enemy == None) || (Pawn == None) )
        log("HERE 3 Enemy "$Enemy$" pawn "$Pawn);

    if ( (Enemy == FailedHuntEnemy) && (Level.TimeSeconds == FailedHuntTime) )
    {
        if ( !Enemy.Controller.bIsPlayer )
            FindNewEnemy();

        if ( Enemy == FailedHuntEnemy )
        {
            GoalString = "FAILED HUNT - HANG OUT";
            if ( EnemyVisible() )
                bCanCharge = false;
            else //hack: don't warp to a player start
            {
                WanderOrCamp(true);
                return;
            }
        }
    }

    bOldForcedCharge = bMustCharge;
    bMustCharge = false;
    enemyDist = VSize(Pawn.Location - Enemy.Location);
    AdjustedCombatStyle = CombatStyle;
    Aggression = 1.5 * FRand() - 0.8 + 2 * AdjustedCombatStyle
                + FRand() * (Normal(Enemy.Velocity - Pawn.Velocity) Dot Normal(Enemy.Location - Pawn.Location));
    if ( Enemy.Weapon != None )
        Aggression += 2 * Enemy.Weapon.SuggestDefenseStyle();
    if ( enemyDist > MAXSTAKEOUTDIST )
        Aggression += 0.5;
    if ( (Pawn.Physics == PHYS_Walking) || (Pawn.Physics == PHYS_Falling) )
    {
        if (Pawn.Location.Z > Enemy.Location.Z + TACTICALHEIGHTADVANTAGE)
            Aggression = FMax(0.0, Aggression - 1.0 + AdjustedCombatStyle);
        else if ( (Skill < 4) && (enemyDist > 0.65 * MAXSTAKEOUTDIST) )
        {
            bFarAway = true;
            Aggression += 0.5;
        }
        else if (Pawn.Location.Z < Enemy.Location.Z - Pawn.CollisionHeight) // below enemy
            Aggression += CombatStyle;
    }

    if ( !EnemyVisible() )
    {
        GoalString = "Enemy not visible";
        if ( !bCanCharge )
        {
            GoalString = "Stake Out";
            DoStakeOut();
        }
        else
        {
            GoalString = "Hunt";
            GotoState('Hunting');
        }
        return;
    }

    // see enemy - decide whether to charge it or strafe around/stand and fire
    Target = Enemy;
    if( Monster(Pawn).PreferMelee() || (bCanCharge && bOldForcedCharge) )
    {
        GoalString = "Charge";
        DoCharge();
        return;
    }

    if ( bCanCharge && (Skill < 5) && bFarAway && (Aggression > 1) && (FRand() < 0.5) )
    {
        GoalString = "Charge closer";
        DoCharge();
        return;
    }

    if ( !Monster(Pawn).PreferMelee() && (FRand() > 0.17 * (skill - 1)) && !DefendMelee(enemyDist) )
    {
        GoalString = "Ranged Attack";
        DoRangedAttackOn(Enemy);
        return;
    }

    if ( bCanCharge )
    {
        if ( Aggression > 1 )
        {
            GoalString = "Charge 2";
            DoCharge();
            return;
        }
    }

    if ( !Pawn.bCanStrafe )
    {
        GoalString = "Ranged Attack";
        DoRangedAttackOn(Enemy);
        return;
    }

    GoalString = "Do tactical move";
    if ( !Monster(Pawn).RecommendSplashDamage() && Monster(Pawn).bCanDodge && (FRand() < 0.7) && (FRand()*Skill > 3) )
    {
        GetAxes(Pawn.Rotation,X,Y,Z);
        GoalString = "Try to Duck ";
        if ( FRand() < 0.5 )
        {
            Y *= -1;
            TryToDuck(Y, true);
        }
        else
            TryToDuck(Y, false);
    }
    DoTacticalMove();
}

defaultproperties
{
}
