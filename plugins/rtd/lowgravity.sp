/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//************************************//
//  -  Roll The Dice: Low Gravity  -  //
//************************************//

float g_fBaseGravity[MAXPLAYERS+1] = {0.0, ...};
float g_fLowGravityMultiplier = 0.25;

void LowGravity_Proc(const char[] sSettings){

	g_fLowGravityMultiplier = StringToFloat(sSettings);

}

void LowGravity_Perk(int client, bool apply){

	if(apply)
		LowGravity_ApplyPerk(client);
	
	else
		SetEntityGravity(client, g_fBaseGravity[client]);

}

void LowGravity_ApplyPerk(int client){

	g_fBaseGravity[client] = GetEntityGravity(client);
	SetEntityGravity(client, g_fLowGravityMultiplier);

}