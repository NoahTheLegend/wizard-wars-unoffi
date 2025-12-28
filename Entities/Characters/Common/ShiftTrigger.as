#include "EntropistCommon.as"
#include "SpellUtils.as";
#include "MagicCommon.as"

void onInit( CBlob@ this )
{
    this.addCommandID("shiftpress");
    this.addCommandID("negentropy");
}

void onTick( CBlob@ this )
{
    if (!this.isMyPlayer()) { return; }

    CControls@ controls = getControls();
    CBitStream params;

    //EntropistInfo@ entropist;

    if (controls.isKeyPressed(KEY_LSHIFT))
    {
        if(!this.get_bool("shifting"))
        {
            params.write_bool(true);

            this.set_bool("shifting", true);

            ManaInfo@ manaInfo;
			if (this.get("manaInfo", @manaInfo) && manaInfo.mana > 0)
            {
				this.set_bool("shift_shoot", true);
                params.write_bool(true);
			}
            else params.write_bool(false);

            this.SendCommand(this.getCommandID("shiftpress"), params);
        }
    }
    else
    {
        if(this.get_bool("shifting"))
        {
            params.write_bool(false);
            this.SendCommand(this.getCommandID("shiftpress"), params);
            this.set_bool("shifting", false);
            this.set_bool("shift_shoot", false);
        }
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("shiftpress"))
    {
        if(params.read_bool())
        {
            this.set_bool("shifting", true);

            if (params.read_bool())
            {
                this.set_bool("shift_shoot", true);
			}
        }
        else
        {
            this.set_bool("shifting", false);
            this.set_bool("shift_shoot", false);
        }
    }
    /*
    if (cmd == this.getCommandID("negentropy"))
    {
        CastNegentropy(this);
    }
    */
}