/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**********************************//
//  -  Roll The Dice: Criticals  -  //
//**********************************//

#define MINICRIT TFCond_Buffed
#define FULLCRIT TFCond_CritOnFirstBlood

bool g_bFullCrits[MAXPLAYERS+1] = {false, ...};
bool g_bCriticals_FullCrits = false;

void Criticals_Proc(const char[] sSettings){

	g_bCriticals_FullCrits = view_as<bool>(StringToInt(sSettings));

}

void Criticals_Perk(int client, bool apply){

	if(apply)
		Criticals_ApplyPerk(client);

	else
		Criticals_RemovePerk(client);

}

void Criticals_ApplyPerk(int client){

	g_bFullCrits[client] = g_bCriticals_FullCrits;
	
	TF2_AddCondition(client, g_bFullCrits[client] ? FULLCRIT : MINICRIT);

}

void Criticals_RemovePerk(int client){
	
	TF2_RemoveCondition(client, g_bFullCrits[client] ? FULLCRIT : MINICRIT);

}