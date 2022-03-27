/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*********************************//
//  -  Roll The Dice: Big Head  -  //
//*********************************//

#define	ATTRIB_VOICEPITCH 2048

bool	g_bHasBigHead[MAXPLAYERS+1]	= {false, ...};
float	g_fBigHeadMultiplier		= 2.0;

void BigHead_Proc(const char[] sSettings){

	g_fBigHeadMultiplier = StringToFloat(sSettings);

}

void BigHead_Perk(int client, bool apply){

	g_bHasBigHead[client] = apply;
	
	if(apply)
		TF2Attrib_SetByDefIndex(client, ATTRIB_VOICEPITCH, 1/g_fBigHeadMultiplier);

	else
		TF2Attrib_RemoveByDefIndex(client, ATTRIB_VOICEPITCH);

}

void BigHead_OnPlayerRunCmd(client){

	if(!g_bHasBigHead[client])
		return;

	SetEntPropFloat(client, Prop_Send, "m_flHeadScale", g_fBigHeadMultiplier);

}