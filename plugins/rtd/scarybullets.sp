/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**************************************//
//  -  Roll The Dice: Scary Bullets  -  //
//**************************************//

#define SCARYBULLETS_PARTICLE "ghost_glow"

int		g_bHasScaryBullets[MAXPLAYERS+1]	= {false, ...};
int		g_bScaryParticle[MAXPLAYERS+1]		= {INVALID_ENT_REFERENCE, ...};
float	g_fScaryStunDuration				= 3.0;

void ScaryBullets_Proc(const char[] sSettings){

	g_fScaryStunDuration = StringToFloat(sSettings);

}

void ScaryBullets_Start(){

	HookEvent("player_hurt", Event_ScaryBullets_PlayerHurt);

}

void ScaryBullets_Perk(int client, bool apply){

	if(apply)
		ScaryBullets_ApplyPerk(client);
	
	else
		ScaryBullets_RemovePerk(client);

}

void ScaryBullets_ApplyPerk(int client){

	g_bHasScaryBullets[client] = true;
	
	if(g_bScaryParticle[client] < 0)
		g_bScaryParticle[client] = EntIndexToEntRef(CreateParticle(client, SCARYBULLETS_PARTICLE));

}

void ScaryBullets_RemovePerk(int client){

	int iParticle = EntRefToEntIndex(g_bScaryParticle[client]);
	if(iParticle > MaxClients && IsValidEntity(iParticle))
		AcceptEntityInput(iParticle, "Kill");
	
	g_bScaryParticle[client] = INVALID_ENT_REFERENCE;
	g_bHasScaryBullets[client] = false;

}

public void Event_ScaryBullets_PlayerHurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(attacker))			return;

	if(!g_bHasScaryBullets[attacker])		return;

	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(attacker == victim)					return;
	if(!IsClientInGame(victim))				return;
	if(victim < 1 || victim > MaxClients)	return;
	
	if(IsPlayerAlive(victim) && GetEventInt(hEvent, "health") > 0 && !TF2_IsPlayerInCondition(victim, TFCond_Dazed))
		TF2_StunPlayer(victim, g_fScaryStunDuration, _, TF_STUNFLAGS_GHOSTSCARE, attacker);

}