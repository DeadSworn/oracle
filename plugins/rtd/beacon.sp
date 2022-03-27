/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*******************************//
//  -  Roll The Dice: Beacon  -  //
//*******************************//

#define SOUND_BEEP "buttons/blip1.wav"

bool	g_bIsBeaconed[MAXPLAYERS+1]		= {false, ...};
float	g_fBeaconInterval				= 1.0;
float	g_fBeaconRadius					= 375.0;
int		g_iSpriteBeam, g_iSpriteHalo;

void Beacon_Proc(const char[] sSettings){

	char[][] sPieces = new char[2][4];
	ExplodeString(sSettings, ",", sPieces, 2, 4);

	g_fBeaconInterval	= StringToFloat(sPieces[0]);
	g_fBeaconRadius		= StringToFloat(sPieces[1]);

}

void Beacon_Start(){

	PrecacheSound(SOUND_BEEP);
	g_iSpriteBeam = PrecacheModel("materials/sprites/laser.vmt");
	g_iSpriteHalo = PrecacheModel("materials/sprites/halo01.vmt");

}

void Beacon_Perk(int client, bool apply){

	if(apply)
		Beacon_ApplyPerk(client);

	else
		g_bIsBeaconed[client] = false;

}

void Beacon_ApplyPerk(int client){

	CreateTimer(g_fBeaconInterval, Timer_BeaconBeep, GetClientSerial(client), TIMER_REPEAT);
	g_bIsBeaconed[client] = true;

}

public Action Timer_BeaconBeep(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;

	if(!g_bIsBeaconed[client])
		return Plugin_Stop;

	Beacon_Beep(client);

	return Plugin_Continue;

}

void Beacon_Beep(int client){

	float fPos[3]; GetClientAbsOrigin(client, fPos);
	fPos[2] += 10.0;

	int iColorGra[4] = {128,128,128,255};
	int iColorRed[4] = {255,75,75,255};
	int iColorBlu[4] = {75,75,255,255};

	TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 15, 0.5, 5.0, 0.0, iColorGra, 10, 0);
	TE_SendToAll();

	if(GetClientTeam(client) == _:TFTeam_Red)
		TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorRed, 10, 0);

	else
		TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorBlu, 10, 0);

	TE_SendToAll();

	EmitSoundToAll(SOUND_BEEP, client);

}