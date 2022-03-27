/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*****************************************//
//  -  Roll The Dice: Explosive Arrows  -  //
//*****************************************//

bool	g_bHasExplosiveArrows[MAXPLAYERS+1] = {false, ...};
char	g_sExplosiveArrowsDamage[8] = "100";
char	g_sExplosiveArrowsRadius[8] = "80";
float	g_fExplosiveArrowsForce = 100.0;
Handle	g_hExplosiveArrows = INVALID_HANDLE;

void ExplosiveArrows_Proc(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	strcopy(g_sExplosiveArrowsDamage, 8, sPieces[0]);
	strcopy(g_sExplosiveArrowsRadius, 8, sPieces[1]);
	g_fExplosiveArrowsForce = StringToFloat(sPieces[3]);

}

void ExplosiveArrows_Start(){

	delete g_hExplosiveArrows;
	g_hExplosiveArrows = CreateArray();

}

void ExplosiveArrows_Perk(int client, bool apply){

	g_bHasExplosiveArrows[client] = apply;

}

void ExplosiveArrows_OnEntityCreated(int iEnt, const char[] sClassname){

	if(ExplosiveArrows_ValidClassname(sClassname))
		SDKHook(iEnt, SDKHook_Spawn, Timer_ExplosiveArrows_ProjectileSpawn);

}

public void Timer_ExplosiveArrows_ProjectileSpawn(int iProjectile){

	int iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");

	if(iLauncher < 1 || !IsValidClient(iLauncher) || !IsPlayerAlive(iLauncher))
		return;

	if(!g_bHasExplosiveArrows[iLauncher])
		return;

	if(FindValueInArray(g_hExplosiveArrows, iProjectile) > -1)
		return;

	PushArrayCell(g_hExplosiveArrows, iProjectile);
	SDKHook(iProjectile, SDKHook_StartTouchPost, ExplosiveArrows_ProjectileTouch);

}

public void ExplosiveArrows_ProjectileTouch(int iEntity, int iOther){

	int iExplosion = CreateEntityByName("env_explosion");
	RemoveFromArray(g_hExplosiveArrows, FindValueInArray(g_hExplosiveArrows, iEntity));

	if(!IsValidEntity(iExplosion))
		return;

	DispatchKeyValue(iExplosion, "iMagnitude", g_sExplosiveArrowsDamage);
	DispatchKeyValue(iExplosion, "iRadiusOverride", g_sExplosiveArrowsRadius);
	DispatchKeyValueFloat(iExplosion, "DamageForce", g_fExplosiveArrowsForce);
	
	DispatchSpawn(iExplosion);
	ActivateEntity(iExplosion);

	SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity"));
	
	float fPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);

	TeleportEntity(iExplosion, fPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iExplosion, "Explode");
	AcceptEntityInput(iExplosion, "Kill");

}

bool ExplosiveArrows_ValidClassname(const char[] sCls){

	if(StrEqual(sCls, "tf_projectile_healing_bolt")
	|| StrEqual(sCls, "tf_projectile_arrow"))
		return true;

	return false;

}