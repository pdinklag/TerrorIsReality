class TIRScorpion extends ONSRV
    HideDropDown
    CacheExempt;

#exec OBJ LOAD FILE=Resources\TIR_rc.u PACKAGE=TerrorIsReality

var() int RegenPerSecond;

var() int BladeDamage;
var() bool bBladesBreak;

event PreBeginPlay() {
    DriverWeapons.Length = 0;
}

//override to make blade breaking optional
simulated event Tick(float dt) {
    local Coords ArmBaseCoords, ArmTipCoords;
    local vector HitLocation, HitNormal;
    local actor Victim;

    Super(ONSWheeledCraft).Tick(dt);

    // Left Blade Arm System
    if(Role == ROLE_Authority && bWeaponIsAltFiring && !bLeftArmBroke)
    {
        ArmBaseCoords = GetBoneCoords('CarLShoulder');
        ArmTipCoords = GetBoneCoords('LeftBladeDummy');
        Victim = Trace(HitLocation, HitNormal, ArmTipCoords.Origin, ArmBaseCoords.Origin);

        if(Victim != None && Victim.bBlockActors)
        {
            if(Victim.IsA('Pawn') && !Victim.IsA('Vehicle'))
            {
                Pawn(Victim).TakeDamage(BladeDamage, self, HitLocation, Velocity * 100, class'DamTypeSlayerBlade');
            }
            else if(bBladesBreak)
            {
                bLeftArmBroke = True;
                bClientLeftArmBroke = True;
                BladeBreakOff(4, 'CarLSlider', class'ONSRVLeftBladeBreakOffEffect');
                // We use slot 4 here because slots 0-3 can be used by BigWheels mutator.
            }
        }
    }
    
    if(Role < ROLE_Authority && bClientLeftArmBroke)
    {
        bLeftArmBroke = True;
        bClientLeftArmBroke = False;
        BladeBreakOff(4, 'CarLSlider', class'ONSRVLeftBladeBreakOffEffect');
    }

    // Right Blade Arm System
    if (Role == ROLE_Authority && bWeaponIsAltFiring && !bRightArmBroke)
    {
        ArmBaseCoords = GetBoneCoords('CarRShoulder');
        ArmTipCoords = GetBoneCoords('RightBladeDummy');
        Victim = Trace(HitLocation, HitNormal, ArmTipCoords.Origin, ArmBaseCoords.Origin);

        if (Victim != None && Victim.bBlockActors)
        {
            if (Victim.IsA('Pawn') && !Victim.IsA('Vehicle'))
            {
                Pawn(Victim).TakeDamage(BladeDamage, self, HitLocation, Velocity * 100, class'DamTypeSlayerBlade');
            }
            else if(bBladesBreak)
            {
                bRightArmBroke = True;
                bClientRightArmBroke = True;
                BladeBreakOff(5, 'CarRSlider', class'ONSRVRightBladeBreakOffEffect');
            }
        }
    }
    if (Role < ROLE_Authority && bClientRightArmBroke)
    {
        bRightArmBroke = True;
        bClientRightArmBroke = False;
        BladeBreakOff(5, 'CarRSlider', class'ONSRVRightBladeBreakOffEffect');
    }
    
    if(Health < HealthMax && RegenPerSecond > 0)
        Health = Min(HealthMax, Health + int(float(RegenPerSecond) * dt));
}

function DriverLeft() {
    Super.DriverLeft();
    
    Health = 0;
    GotoState('VehicleDestroyed');
}

simulated event TeamChanged() {
    Super.TeamChanged();
    
    Skins[0] = RedSkin;
}

function Suicide() {
    KDriverLeave(true);
}

event RanInto(Actor Other) {
    local vector Momentum;
    local float Speed;

    if (Pawn(Other) == None || Vehicle(Other) != None || Other == Instigator || Other.Role != ROLE_Authority)
        return;

    Speed = VSize(Velocity);
    if (Speed > MinRunOverSpeed) {
        Momentum = Velocity * 0.25 * Other.Mass;

        if(Controller != None && Controller.SameTeamAs(Pawn(Other).Controller))
            Momentum += Speed * 0.25 * Other.Mass * Normal(Velocity cross vect(0,0,1));
            
        if(RanOverSound != None)
            PlaySound(RanOverSound,,TransientSoundVolume*2.5);

           Other.TakeDamage(BladeDamage, Self, Other.Location, Velocity * 100, RanOverDamageType);
    }
}

defaultproperties {
    VehiclePositionString="in a Slayer"
    VehicleNameString="Slayer"
    
    BladeDamage=1000
    bBladesBreak=False
    
    Health=2000
    HealthMax=2000
    RegenPerSecond=0
    
    MomentumMult=0.01
    DriverDamageMult=0
    
    VehicleMass=10.0
    
    GearRatios[0]=-0.8
    GearRatios[1]=1.0
    GearRatios[2]=1.2
    GearRatios[3]=1.4
    GearRatios[4]=1.6
    
    //TorqueCurve=(Points=((InVal=0,OutVal=18.0),(InVal=200,OutVal=30.0),(InVal=1500,OutVal=36.0),(InVal=2800,OutVal=0.0)))
    TorqueCurve=(Points=((InVal=0,OutVal=50.0),(InVal=200,OutVal=65.0),(InVal=1500,OutVal=75.0),(InVal=2800,OutVal=0.0)))
    MaxSteerAngleCurve=(Points=((InVal=0,OutVal=25.0),(InVal=1500.0,OutVal=20.0),(InVal=1000000000.0,OutVal=20.0)))
    
    bDoStuntInfo=False
    
    RedSkin=Shader'TerrorIsReality.GTRVRedTeamFinal'
    BlueSkin=Shader'TerrorIsReality.GTRVRedTeamFinal'
    
    RanOverDamageType=class'DamTypeTIRRoadkill'
    CrushedDamageType=class'DamTypeTIRPancake'
    
    bCanBeBaseForPawns=False
    
    HornSounds(0)=None
    HornSounds(1)=None
    //HornSounds(0)=Sound'ONSVehicleSounds-S.Horn06'
    //HornSounds(1)=Sound'ONSVehicleSounds-S.Dixie_Horn'
}
