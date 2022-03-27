/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***************************************//
//  -  Roll The Dice: Eye for an Eye  -  //
//***************************************//

bool g_bHasEyeForAnEye[MAXPLAYERS+1] = {false, ...};

void EyeForAnEye_Start(){

	HookEvent("player_hurt", EyeForAnEye_PlayerHurt);

}

void EyeForAnEye_Perk(int client, bool apply){

	g_bHasEyeForAnEye[client] = apply;

}

public void EyeForAnEye_PlayerHurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!g_bHasEyeForAnEye[attacker])
		return;
	
	SDKHooks_TakeDamage(attacker, 0, 0, float(GetEventInt(hEvent, "damageamount")));

}