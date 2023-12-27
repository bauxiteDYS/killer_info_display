#pragma semicolon 1

#include <sourcemod>
#include <neotokyo>

char class_name[][] = {
	"Unknown",
	"Recon",
	"Assault",
	"Support"
};

public Plugin myinfo = 
{
	name		= "Killer Info Display for NT and streamlined",
	author		= "Berni, gH0sTy, Smurfy1982, Snake60, bauxite",
	description	= "Displays the name, weapon, health and class of player that killed you",
	version		= "0.2.0",
	url		= "https://github.com/bauxiteDYS/SM-NT-Killer-Info-Display/tree/NT",
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
	
	float clientVec[3];
	float attackerVec[3];
	GetClientAbsOrigin(client, clientVec);
	GetClientAbsOrigin(attacker, attackerVec);
	
	distance = GetVectorDistance(clientVec, attackerVec);
	
	distance = distance * 0.01905;
	
	// Print To Panel
	
	Handle panel= CreatePanel();
	char buffer[128];
	Format(buffer, sizeof(buffer), "%N killed you", attacker);
	SetPanelTitle(panel, buffer);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
	Format(buffer, sizeof(buffer), "Weapon:   %s", weapon);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "Health:      %d HP", healthLeft);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "Class:        %s", class_name[GetPlayerClass(attacker)]);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		
	Format(buffer, sizeof(buffer), "Distance:  %.1f Meters", distance);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		
	DrawPanelItem(panel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

	SetPanelCurrentKey(panel, 10);
	SendPanelToClient(panel, client, Handler_DoNothing, 20);
	CloseHandle(panel);
	
	return Plugin_Continue;
}

public Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {}
