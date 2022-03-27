/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***********************************//
//  -  Roll The Dice: No Gravity  -  //
//***********************************//

float g_fNoGravBaseGravity[MAXPLAYERS+1] = {0.0, ...};

void NoGravity_Perk(int client, bool apply){

	if(apply)
		NoGravity_ApplyPerk(client);
	
	else
		SetEntityGravity(client, g_fNoGravBaseGravity[client]);

}

void NoGravity_ApplyPerk(int client){

	g_fBaseGravity[client] = GetEntityGravity(client);
	SetEntityGravity(client, 0.01);

}