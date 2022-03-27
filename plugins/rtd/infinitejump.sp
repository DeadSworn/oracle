/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**************************************//
//  -  Roll The Dice: Infinite Jump  -  //
//**************************************//

bool g_bHasInfiniteDoubleJump[MAXPLAYERS+1] = {false, ...};

void InfiniteJump_Perk(int client, bool apply){

	g_bHasInfiniteDoubleJump[client] = apply;

}

void InfiniteJump_OnPlayerRunCmd(int client, int iButtons){

	if(!g_bHasInfiniteDoubleJump[client])
		return;

	if(iButtons & IN_JUMP)
		SetEntProp(client, Prop_Send, "m_iAirDash", 0);

}