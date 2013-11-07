class TIRGame extends xDeathMatch
    config;
    
var config array<class<Monster> > MonsterTypes;
var config int MonsterHealth;

var config int MonstersPerSecond;
var config int NumMonstersWanted;

var config class<ONSVehicle> PlayerVehicle;
var config Sound Music;

var BackgroundMusicInfo BackgroundMusic;

var int NumMonsters;

event PreBeginPlay() {
    Super.PreBeginPlay();
    
    GameReplicationInfo.bNoTeamSkins = true;
    GameReplicationInfo.bForceNoPlayerLights = true;
    GameReplicationInfo.bNoTeamChanges = true;
}

function NotifyKilled(Controller Killer, Controller Killed, Pawn KilledPawn) {
    Super.NotifyKilled(Killer, Killed, KilledPawn);
    
    if(KilledPawn.IsA('Monster'))
        NumMonsters--;
}

function bool CanLeaveVehicle(Vehicle V, Pawn P) {
    return false;
}

function DriverLeftVehicle(Vehicle V, Pawn P) {
    Super.DriverLeftVehicle(V, P);

    V.Health = 0;
    V.GotoState('VehicleDestroyed');
    
    P.Died(None, class'Suicided', P.Location);
}

function RestartPlayer(Controller aPlayer) {
    local ONSVehicle V;

    Super.RestartPlayer(aPlayer);
    
    if(aPlayer.Pawn != None)
    {
        aPlayer.Pawn.SetCollision(false, false);
        
        V = aPlayer.Spawn(PlayerVehicle, None, '', aPlayer.Pawn.Location, aPlayer.Pawn.Rotation);
        V.bTeamLocked = false;
        V.SetTeamNum(255);
        V.KDriverEnter(aPlayer.Pawn);
    }
}

function bool IsEligibleSpawnPoint(NavigationPoint Nav, class<Monster> MonsterType) {
    local Actor A;

    if(Nav.IsA('FlyingPathNode'))
        return false;

    if(!Nav.IsA('PathNode'))
        return false;
    
    foreach Nav.VisibleCollidingActors(class'Actor', A, FMax(MonsterType.default.CollisionRadius, MonsterType.default.CollisionHeight))
    {
        if(A.bBlockActors)
            return false;
    }
    
    return true;
}

function NavigationPoint FindMonsterSpawnPoint(class<Monster> MonsterType) {
    local NavigationPoint Nav;
    
    for(Nav = Level.NavigationPointList; Nav != None; Nav = Nav.nextNavigationPoint)
    {
        if(IsEligibleSpawnPoint(Nav, MonsterType))
            return Nav;
    }
    return None;
}

function Monster SpawnMonster() {
    local class<Monster> MonsterType;
    local Monster Monster;
    local NavigationPoint SpawnPoint;
    
    MonsterType = MonsterTypes[Rand(MonsterTypes.Length)];
    
    SpawnPoint = FindMonsterSpawnPoint(MonsterType);
    if(SpawnPoint != None)
    {
        Monster = Spawn(MonsterType, None, '', SpawnPoint.Location, SpawnPoint.Rotation);
        if(Monster != None)
        {
            if(Monster.Controller != None)
                Monster.Controller.Destroy();
        
            Monster.Controller = Monster.Spawn(class'TIRMonsterController');
            Monster.Controller.Possess(Monster);
        
            return Monster;
        }
    }
    return None;
}

state MatchInProgress {
    function BeginState() {
        Super.BeginState();
        
        if(Music != None) {
            BackgroundMusic = Spawn(class'BackgroundMusicInfo');
            BackgroundMusic.Music = Music;
        }
    }

    function Timer() {
        local Monster Monster;
        local int i;
        
        Super.Timer();
        
        if(NumMonsters < NumMonstersWanted) {
            for(i = 0; i < Min(MonstersPerSecond, NumMonstersWanted - NumMonsters); i++) {
                Monster = SpawnMonster();
                
                if(Monster != None) {
                    if(MonsterHealth > 0) {
                        Monster.Health = MonsterHealth;
                        Monster.HealthMax = MonsterHealth;
                    }
                    NumMonsters++;
                }
            }
        }
    }
    
    function EndState() {
        if(BackgroundMusic != None)
            BackgroundMusic.Destroy();
        
        Super.EndState();
    }
}

defaultproperties {
    MonsterTypes(0)=class'SkaarjPack.Krall'
    MonsterHealth=25

    MonstersPerSecond=10
    NumMonstersWanted=250
    
    PlayerVehicle=class'TIRScorpion'
    Music=Sound'TerrorIsReality.TerrorIsReality'

    TimeLimit=10
    GoalScore=100

    ScreenShotName="UT2004Thumbnails.InvasionShots"
    LoginMenuClass="GUI2K4.UT2K4InvasionLoginMenu"
    bForceNoPlayerLights=True

    HUDType="TerrorIsReality.TIRHUD"
    ScoreboardType="XInterface.ScoreBoardDeathMatch"

    MutatorClass="Skaarjpack.InvasionMutator"
    MapListType="TerrorIsReality.MapListTIR"
    DeathMessageClass=class'SkaarjPack.InvasionDeathMessage'
    GameReplicationInfoClass=class'TerrorIsReality.TIRGameReplicationInfo'
    bPlayersMustBeReady=True

    Acronym="TIR"
    MapPrefix="DM"

    GameName="Terror is Reality"
    Description="Kill as many monsters as you can to WIN BIG!"
    
    bAllowVehicles=True
}
