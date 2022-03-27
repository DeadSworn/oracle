/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**************************************//
//  -  Roll The Dice: Funny Feeling  -  //
//**************************************//

int		g_iBaseFunnyFov[MAXPLAYERS+1]		= {75, ...};
bool	g_bHasFunnyFeeling[MAXPLAYERS+1]	= {false, ...};
bool	g_bHasFunnyFeelingBug[MAXPLAYERS+1]	= {false, ...};
int		g_iDesiredFunnyFov = 160;

void FunnyFeeling_Proc(const char[] sSettings){

	g_iDesiredFunnyFov = StringToInt(sSettings);

}

void FunnyFeeling_Perk(int client, bool apply){

	if(IsFakeClient(client))
		return;

	if(apply)
		FunnyFeeling_ApplyPerk(client);

	else
		FunnyFeeling_RemovePerk(client);

}

void FunnyFeeling_ApplyPerk(int client){

	g_iBaseFunnyFov[client] = GetEntProp(client, Prop_Send, "m_iFOV");
	SetEntProp(client, Prop_Send, "m_iFOV", g_iDesiredFunnyFov);

	g_bHasFunnyFeeling[client] = true;

}

void FunnyFeeling_RemovePerk(int client){

	g_bHasFunnyFeelingBug[client] = TF2_IsPlayerInCondition(client, TFCond_Taunting);

	SetEntProp(client, Prop_Send, "m_iFOV", g_iBaseFunnyFov[client]);

	g_bHasFunnyFeeling[client] = false;

}

void FunnyFeeling_OnConditionRemoved(int client, TFCond condition){

	if(!IsValidClient(client))
		return;

	if(g_bHasFunnyFeelingBug[client]){
	
		SetEntProp(client, Prop_Send, "m_iFOV", g_iBaseFunnyFov[client]);
		g_bHasFunnyFeelingBug[client] = false;
	
	}

	if(!g_bHasFunnyFeeling[client])
		return;

	if(condition != TFCond_Zoomed)
		return;

	SetEntProp(client, Prop_Send, "m_iFOV", g_iDesiredFunnyFov);

}