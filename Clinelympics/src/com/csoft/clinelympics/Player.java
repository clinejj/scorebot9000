package com.csoft.clinelympics;

import java.util.HashMap;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Player {
	private String playerID;
	private String playerName;
	private String teamName;
	private Key playerKey;
	private HashMap<Integer, Score> scores;
	
	public static final String keyName = "playerList";
	public static final String keyKind = "Players";
	public static final String entityKind = "player";
	public static final String playerIDName = "playerID";
	public static final String playerNameName = "playerName";
	public static final String teamNameName = "teamName";
	
	public Player() {
		playerKey = KeyFactory.createKey(keyKind, keyName);
		scores = new HashMap<Integer, Score>();
	}
	
	public Player(String pID, String pName, String tName) {
		playerKey = KeyFactory.createKey(keyKind, keyName);
		playerID = pID;
		playerName = pName;
		teamName = tName;
		scores = new HashMap<Integer, Score>();
	}
	
	public Player(Entity pA) {
		playerID = (String) pA.getProperty(playerIDName);
		playerName = (String) pA.getProperty(playerNameName);
		teamName = (String) pA.getProperty(teamNameName);
		playerKey = KeyFactory.createKey(keyKind, keyName);
		scores = new HashMap<Integer, Score>();
	}
	
	public void setPlayerID(String playerID) {
		this.playerID = playerID;
	}
	public String getPlayerID() {
		return playerID;
	}
	public void setPlayerName(String playerName) {
		this.playerName = playerName;
	}
	public String getPlayerName() {
		return playerName;
	}
	public void setTeamName(String teamName) {
		this.teamName = teamName;
	}
	public String getTeamName() {
		return teamName;
	}
	
	public void addScore(Score newScore) {
		scores.put(newScore.getGameID(), newScore);
	}
	
	public void removeScore(Score newScore) {
		scores.remove(newScore);
	}
	
	public HashMap<Integer, Score> getScores() {
		return scores;
	}
	
	public Integer getScore(int gID) {
		if (scores.containsKey(gID)) {
			return scores.get(gID).getPlayerScore();
		} else {
			return null;
		}
	}
	
	public Entity createEntity() {
		Entity player = new Entity(entityKind, playerKey);
		player.setProperty(playerIDName, playerID);
		player.setProperty(playerNameName, playerName);
		player.setProperty(teamNameName, teamName);
		
		return player;
	}
}
