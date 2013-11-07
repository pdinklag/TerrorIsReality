class BackgroundMusicInfo extends ReplicationInfo;

var Sound Music;

var PlayerController PC;
var float NextMusicTime;

replication {
    reliable if(Role == ROLE_Authority && bNetInitial)
        Music;
}

simulated event PostNetBeginPlay() {
    Super.PostNetBeginPlay();
    PC = Level.GetLocalPlayerController();
}

simulated event Tick(float dt) {
    if(Level.NetMode != NM_DedicatedServer && Level.TimeSeconds > NextMusicTime) {
        PC.ClientPlaySound(Music, true, 2.0f); //, SLOT_Talk);
        NextMusicTime = Level.TimeSeconds + Music.Duration * Level.TimeDilation; //perfect timing
    }
}

defaultproperties {
    NetUpdateFrequency=1
}
