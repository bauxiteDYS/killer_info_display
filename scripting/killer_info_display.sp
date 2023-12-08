#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo = 
{
	name		= "Killer Info Display for NT",
	author		= "Berni, gH0sTy, Smurfy1982, Snake60",
	description	= "Displays the health, the armor and the weapon of the player who has killed you",
	version		= "0.1.5",
	url		= "http://forums.alliedmods.net/showthread.php?p=670361",
};

public OnPluginStart()
{	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (client == 0 || attacker == 0 || client == attacker) 
	{
		return Plugin_Continue;
	}

	char weapon[32];
	
	float distance;

	int healthLeft = GetClientHealth(attacker);

	GetEventString(event, "weapon", weapon, sizeof(weapon));		
	
	float entityVec[3];
	float targetVec[3];
	GetClientAbsOrigin(client, entityVec);
	GetClientAbsOrigin(attacker, targetVec);
	
	distance = GetVectorDistance(entityVec, targetVec);
	
	distance = distance * 0.01905;
	
	// Print To Panel
	
	Handle panel= CreatePanel();
	char buffer[128];
	Format(buffer, sizeof(buffer), "%N killed you", attacker);
	SetPanelTitle(panel, buffer);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		
	Format(buffer, sizeof(buffer), "Weapon:   %s", weapon);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "Health:   %d left", healthLeft);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		
	Format(buffer, sizeof(buffer), "Distance:   %.1f Meters", distance);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(panel, 10);
	SendPanelToClient(panel, client, Handler_DoNothing, 20);
	CloseHandle(panel);
	
	return Plugin_Continue;
}

public Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {}
