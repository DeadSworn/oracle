/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//************************************//
//  -  Roll The Dice: Fire Breath  -  //
//************************************//

#define FIREBREATH_SOUND_ATTACK "player/taunt_fire.wav"

bool	g_bHasFireBreath[MAXPLAYERS+1] 			= {false, ...};
float	g_fFireBreathLastAttack[MAXPLAYERS+1]	= {0.0, ...};
float	g_fFireBreathRate						= 2.0;
float	g_fFireBreathCritChance					= 0.05;

void FireBreath_Proc(const char[] sSettings){

	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);

	g_fFireBreathRate		= StringToFloat(sPieces[0]);
	g_fFireBreathCritChance	= StringToFloat(sPieces[1]);

}

void FireBreath_Start(){

	PrecacheSound(FIREBREATH_SOUND_ATTACK);

}

void FireBreath_Perk(int client, bool apply){

	if(apply)
		FireBreath_ApplyPerk(client);
	
	else
		g_bHasFireBreath[client] = false;

}

void FireBreath_ApplyPerk(int client){
	
	g_bHasFireBreath[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);

}

void FireBreath_Voice(int client){

	if(!g_bHasFireBreath[client])
		return;
	
	float fEngineTime = GetEngineTime();
	
	if(fEngineTime < g_fFireBreathLastAttack[client] +g_fFireBreathRate)
		return;
	
	g_fFireBreathLastAttack[client] = fEngineTime;
	
	float fShake[3];
	fShake[0] = GetRandomFloat(-5.0, -25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
	
	FireBreath_Fireball(client);
	EmitSoundToAll(FIREBREATH_SOUND_ATTACK, client);

}

/*
	Code borrowed from: [TF2] Spell casting!
	https://forums.alliedmods.net/showthread.php?p=2054678
*/

void FireBreath_Fireball(client){
	
	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);
	
	int iTeam	= GetClientTeam(client);
	int iSpell	= CreateEntityByName("tf_projectile_spellfireball");
	
	if(!IsValidEntity(iSpell))
		return;
	
	float fVel[3], fBuf[3];
	
	GetAngleVectors(fAng, fBuf, NULL_VECTOR, NULL_VECTOR);
	fVel[0] = fBuf[0]*1100.0; //Speed of a tf2 rocket.
	fVel[1] = fBuf[1]*1100.0;
	fVel[2] = fBuf[2]*1100.0;

	SetEntPropEnt	(iSpell, Prop_Send, "m_hOwnerEntity",	client);
	SetEntProp		(iSpell, Prop_Send, "m_bCritical",		(GetURandomFloat() <= g_fFireBreathCritChance) ? 1 : 0, 1);
	SetEntProp		(iSpell, Prop_Send, "m_iTeamNum",		iTeam, 1);
	SetEntProp		(iSpell, Prop_Send, "m_nSkin",			iTeam-2);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0);
	
	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, fPos, fAng, fVel);

}