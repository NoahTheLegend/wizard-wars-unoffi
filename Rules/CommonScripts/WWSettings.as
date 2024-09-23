// Simple rules logic script

void onInit(CRules@ this)
{		
	//sv_gravity = 0.0f;
	//v_camera_ints = false;
	#ifndef STAGING
	v_no_renderscale = true;
	#endif
	sv_visiblity_scale = 6.0f;
}