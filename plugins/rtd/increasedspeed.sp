/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//****************************************//
//  -  Roll The Dice: Increased Speed  -  //
//****************************************//

#define ATTRIB_SPEED 107 //the player speed attribute

float g_fBaseSpeed[MAXPLAYERS+1] = {0.0, ...};
float g_fIncreasedSpeed_Multiplier = 3.0;

void IncreasedSpeed_Proc(const char[] sSettings){

	g_fIncreasedSpeed_Multiplier = StringToFloat(sSettings);

}

void IncreasedSpeed_Perk(int client, bool apply){

	if(apply)
		IncreasedSpeed_ApplyPerk(client);
	
	else
		IncreasedSpeed_RemovePerk(client);

}

void IncreasedSpeed_ApplyPerk(int client){

	g_fBaseSpeed[client] = GetBaseClassSpeed(client);

	TF2Attrib_SetByDefIndex(client, ATTRIB_SPEED, g_fIncreasedSpeed_Multiplier);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fBaseSpeed[client] *g_fIncreasedSpeed_Multiplier);

}

void IncreasedSpeed_RemovePerk(int client){

	TF2Attrib_RemoveByDefIndex(client, ATTRIB_SPEED);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fBaseSpeed[client]);

}