
/*

	Welcome to the perk manager!
	If you want to change something - CREATE YOUR OWN MODULE.

	Follow this guide for adding/editing perks:
	https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

*/

void ManagePerk(int client, int iPerkId, bool bEnable, int iReason=3, const char[] sReason=""){

	if(ePerks[iPerkId][bIsExternal]){
	
		Call_StartFunction(ePerks[iPerkId][plParent], ePerks[iPerkId][funcCallback]);
		Call_PushCell(client);
		Call_PushCell(iPerkId);
		Call_PushCell(bEnable);
		Call_Finish();
	
		if(!bEnable)
			RemovedPerk(client, iReason, sReason);
		
		return;
	
	}

	switch(iPerkId){
	
		case 0:	Godmode_Perk			(client, bEnable);
		case 1:	Toxic_Perk				(client, bEnable);
		case 2:	LuckySandvich_Perk		(client);
		case 3:	IncreasedSpeed_Perk		(client, bEnable);
		case 4:	Noclip_Perk				(client, bEnable);
		case 5:	LowGravity_Perk			(client, bEnable);
		case 6:	FullUbercharge_Perk		(client, bEnable);
		case 7:	Invisibility_Perk		(client, bEnable);
		case 8:	InfiniteCloak_Perk		(client, bEnable);
		case 9:	Criticals_Perk			(client, bEnable);
		case 10:InfiniteAmmo_Perk		(client, bEnable);
		case 11:ScaryBullets_Perk		(client, bEnable);
		case 12:SpawnSentry_Perk		(client, bEnable);
		case 13:HomingProjectiles_Perk	(client, bEnable);
		case 14:FullRifleCharge_Perk	(client, bEnable);
		case 15:Explode_Perk			(client);
		case 16:Snail_Perk				(client, bEnable);
		case 17:Frozen_Perk				(client, bEnable);
		case 18:Timebomb_Perk			(client);
		case 19:Ignition_Perk			(client);
		case 20:LowHealth_Perk			(client);
		case 21:Drugged_Perk			(client, bEnable);
		case 22:Blind_Perk				(client, bEnable);
		case 23:StripToMelee_Perk		(client, bEnable);
		case 24:Beacon_Perk				(client, bEnable);
		case 25:ForcedTaunt_Perk		(client, bEnable);
		case 26:Monochromia_Perk		(client, bEnable);
		case 27:Earthquake_Perk			(client, bEnable);
		case 28:FunnyFeeling_Perk		(client, bEnable);
		case 29:BadSauce_Perk			(client, bEnable);
		case 30:SpawnDispenser_Perk		(client, bEnable);
		case 31:InfiniteJump_Perk		(client, bEnable);
		case 32:PowerfulHits_Perk		(client, bEnable);
		case 33:BigHead_Perk			(client, bEnable);
		case 34:TinyMann_Perk			(client, bEnable);
		case 35:Firework_Perk			(client, bEnable);
		case 36:DeadlyVoice_Perk		(client, bEnable);
		case 37:StrongGravity_Perk		(client, bEnable);
		case 38:EyeForAnEye_Perk		(client, bEnable);
		case 39:Weakened_Perk			(client, bEnable);
		case 40:NecroMash_Perk			(client, bEnable);
		case 41:ExtraAmmo_Perk			(client);
		case 42:Suffocation_Perk		(client, bEnable);
		case 43:FastHands_Perk			(client, bEnable);
		case 44:Outline_Perk			(client, bEnable);
		case 45:Vital_Perk				(client, bEnable);
		case 46:NoGravity_Perk			(client, bEnable);
		case 47:TeamCriticals_Perk		(client, bEnable);
		case 48:FireTimebomb_Perk		(client);
		case 49:FireBreath_Perk			(client, bEnable);
		case 50:StrongRecoil_Perk		(client, bEnable);
		case 51:Cursed_Perk				(client, bEnable);
		case 52:ExtraThrowables_Perk	(client);
		case 53:PowerPlay_Perk			(client, bEnable);
		case 54:ExplosiveArrows_Perk	(client, bEnable);
		case 55:InclineProblem_Perk		(client, bEnable);
	
	}
	
	if(!bEnable)
		RemovedPerk(client, iReason, sReason);

}

void UpdatePerkPref(int iPerkId){

	char sSettings[PERK_MAX_HIGH];
	strcopy(sSettings, PERK_MAX_HIGH, ePerks[iPerkId][sPref]);

	switch(iPerkId){
	
		case 0:	Godmode_Proc			(sSettings);
		case 1:	Toxic_Proc				(sSettings);
		case 2:	LuckySandvich_Proc		(sSettings);
		case 3:	IncreasedSpeed_Proc		(sSettings);
		case 4:	Noclip_Proc				(sSettings);
		case 5:	LowGravity_Proc			(sSettings);
		//	 6: Full Ubercharge			(no settings)
		case 7:	Invisibility_Proc		(sSettings);
		//	 7: Infinite Cloak			(no settings)
		case 9:	Criticals_Proc			(sSettings);
		case 10:InfiniteAmmo_Proc		(sSettings);
		case 11:ScaryBullets_Proc		(sSettings);
		case 12:SpawnSentry_Proc		(sSettings);
		case 13:HomingProjectiles_Proc	(sSettings);
		//	 14:Full Rifle Charge		(no settings)
		//	 15:Explode					(no settings)
		case 16:Snail_Proc				(sSettings);
		//	 17:Frozen					(no settings)
		case 18:Timebomb_Proc			(sSettings);
		//	 19:Ignition				(no settings)
		case 20:LowHealth_Proc			(sSettings);
		case 21:Drugged_Proc			(sSettings);
		case 22:Blind_Proc				(sSettings);
		case 23:StripToMelee_Proc		(sSettings);
		case 24:Beacon_Proc				(sSettings);
		case 25:ForcedTaunt_Proc		(sSettings);
		//	 26:Monochromia				(no settings)
		case 27:Earthquake_Proc			(sSettings);
		case 28:FunnyFeeling_Proc		(sSettings);
		case 29:BadSauce_Proc			(sSettings);
		case 30:SpawnDispenser_Proc		(sSettings);
		//	 31:Infinite Jump			(no settings)
		case 32:PowerfulHits_Proc		(sSettings);
		case 33:BigHead_Proc			(sSettings);
		case 34:TinyMann_Proc			(sSettings);
		case 35:Firework_Proc			(sSettings);
		case 36:DeadlyVoice_Proc		(sSettings);
		case 37:StrongGravity_Proc		(sSettings);
		//	 38:Eye for an Eye			(no settings)
		case 39:Weakened_Proc			(sSettings);
		//	 40:Necro Mash				(no settings)
		case 41:ExtraAmmo_Proc			(sSettings);
		case 42:Suffocation_Proc		(sSettings);
		case 43:FastHands_Proc			(sSettings);
		//	 44:Outline					(no settings)
		case 45:Vital_Proc				(sSettings);
		//	 46:No Gravity				(no settings)
		case 47:TeamCriticals_Proc		(sSettings);
		case 48:FireTimebomb_Proc		(sSettings);
		case 49:FireBreath_Proc			(sSettings);
		//	 50:Strong Recoil			(no settings)
		//	 51:Cursed					(no settings)
		case 52:ExtraThrowables_Proc	(sSettings);
		//	 53:PowerPlay				(no settings)
		case 54:ExplosiveArrows_Proc	(sSettings);
		//	 55:Incline Problem			(no settings)
	
	}

}

void Forward_OnMapStart(){

	Invisibility_Start();
	InfiniteAmmo_Start();
	HomingProjectiles_Start();
	FullRifleCharge_Start();
	Timebomb_Start();
	Drugged_Start();
	Blind_Start();
	Beacon_Start();
	ForcedTaunt_Start();
	Earthquake_Start();
	ScaryBullets_Start();
	Firework_Start();
	DeadlyVoice_Start();
	EyeForAnEye_Start();
	NecroMash_Start();
	ExtraAmmo_Start();
	FastHands_Start();
	FireTimebomb_Start();
	FireBreath_Start();
	ExplosiveArrows_Start();

}

void Forward_OnClientPutInServer(int client){

	PowerfulHits_OnClientPutInServer(client);

}

void Forward_Voice(int client){

	SpawnSentry_Voice(client);
	SpawnDispenser_Voice(client);
	DeadlyVoice_Voice(client);
	FireBreath_Voice(client);

}

void Forward_OnEntityCreated(int iEntity, const char[] sClassname){

	HomingProjectiles_OnEntityCreated(iEntity, sClassname);
	FastHands_OnEntityCreated(iEntity, sClassname);
	ExplosiveArrows_OnEntityCreated(iEntity, sClassname);

}

void Forward_OnGameFrame(){

	HomingProjectiles_OnGameFrame();

}

void Forward_OnConditionAdded(int client, TFCond condition){

	FullRifleCharge_OnConditionAdded(client, condition);
	ForcedTaunt_OnConditionAdded(client, condition);

}

void Forward_OnConditionRemoved(int client, TFCond condition){

	FullUbercharge_OnConditionRemoved(client, condition);
	FunnyFeeling_OnConditionRemoved(client, condition);
	ForcedTaunt_OnConditionRemoved(client, condition);

}

bool Forward_OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3]){

	InfiniteJump_OnPlayerRunCmd(client, iButtons);
	BigHead_OnPlayerRunCmd(client);
	
	if(Cursed_OnPlayerRunCmd(client, iButtons, fVel))
		return true;
	
	return false;

}

void Forward_OnRemovePerkPre(int client){

	Timebomb_OnRemovePerk(client);
	FireTimebomb_OnRemovePerk(client);

}

bool Forward_AttackIsCritical(int client, int iWeapon){

	StrongRecoil_CritCheck(client, iWeapon);
	
	/*
		if(Something_SetCritical(client)
		|| Something2_SetCritical(client)
		|| Something3_SetCritical(client))
			return true;
	*/

	if(LuckySandvich_SetCritical(client))
		return true;
	
	return false;

}

bool Forward_OnGoombaStomp(int iVictim){
	
	/*
		if(Something_DisableGoomba(client)
		|| Something2_DisableGoomba(client)
		|| Something3_DisableGoomba(client))
			return true;
	*/

	if(Godmode_DisableGoomba(iVictim))
		return true;
	
	return false;

}