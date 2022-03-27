/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//********************************//
//  -  Roll The Dice: Godmode  -  //
//********************************//

#define GODMODE_PARTICLE "powerup_supernova_ready"

bool	g_bHasGodmode[MAXPLAYERS+1] = {false, ...};
int		g_iGodmodeParticle[MAXPLAYERS+1] = {0, ...};
int		g_iPref_Godmode = 0;

void Godmode_Proc(const char[] sSettings){

	g_iPref_Godmode = StringToInt(sSettings);

}

void Godmode_Perk(int client, bool apply){

	if(apply)
		Godmode_ApplyPerk(client);
	
	else
		Godmode_RemovePerk(client);

}

void Godmode_ApplyPerk(int client){

	g_iGodmodeParticle[client] = CreateParticle(client, GODMODE_PARTICLE, _, _, view_as<float>({0.0, 0.0, 12.0}));

	g_bHasGodmode[client] = true;
	SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage);

}

void Godmode_RemovePerk(int client){

	if(g_iGodmodeParticle[client] > MaxClients && IsValidEntity(g_iGodmodeParticle[client])){
	
		AcceptEntityInput(g_iGodmodeParticle[client], "Kill");
		g_iGodmodeParticle[client] = 0;
	
	}

	g_bHasGodmode[client] = false;
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage);

}

public Action Godmode_OnTakeDamage(int iVic, int &iAttacker){

	if(iVic != iAttacker)
		return Plugin_Handled;

	if(g_iPref_Godmode > 0)
		return Plugin_Continue;

	if(g_iPref_Godmode > -1)
		TF2_AddCondition(iVic, TFCond_Bonked, 0.001);

	else
		return Plugin_Handled;

	return Plugin_Continue;

}

bool Godmode_DisableGoomba(int iVic){

	return g_bHasGodmode[iVic];

}