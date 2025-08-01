
namespace HittersWW {
shared enum hits {
    nothing = 0,

    //env
    crush,
    fall,
    water, //splash
    drown,
    fire,   //initial burst (should ignite things)
    burn,   //burn damage
    flying,

    //common actor
    stomp,
    suicide,
    
    //natural
    bite,

    //builders
    builder,

	//knight
	sword,
	shield,
	bomb,

	//archer
	stab,

    //arrows and similar projectiles
    arrow,
    ballista,

    //cata
    cata_stones,

    //siege
    ram,
    explosion,
    keg, //special case

    //traps
    spikes,

    //machinery
    saw,

    //barbarian
    muscles,

	// scrolls
	suddengib,
	
	
	
	orb             = 150,
	wizexplosion    = 151,
    poison          = 152,
    electricity     = 153,
    lifesteal       = 154
};
}
