package com.csoft.scorebot;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Game {
	private int gameID;
	private String gameName;
	private boolean scoreType;	// True = high score
	private int eventID;
	private Key gameKey;
	
	public static final String KEY_NAME = "gameList";
	public static final String KEY_KIND = "Games";
	public static final String ENTITY_KIND = "game";
	public static final String GAME_ID = "gameID";
	public static final String GAME_NAME = "gameName";
	public static final String SCORE_TYPE = "scoreType";
	public static final String EVENT_ID = "eventID";
	
	public Game() {
		gameKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
	}
	
	public Game(int gID, String gName, boolean sType, int eID) {
		gameKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		gameID = gID;
		gameName = gName;
		scoreType = sType;
		eventID = eID;
	}
	
	public Game(Entity eGame) {
		gameKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		gameID = ((Long) eGame.getProperty(GAME_ID)).intValue();
		gameName = (String) eGame.getProperty(GAME_NAME);
		scoreType = (Boolean) eGame.getProperty(SCORE_TYPE);
		eventID = ((Long) eGame.getProperty(EVENT_ID)).intValue();
	}
	
	public void setGameID(int gameID) {
		this.gameID = gameID;
	}
	
	public int getGameID() {
		return gameID;
	}
	
	public void setGameName(String gameName) {
		this.gameName = gameName;
	}
	
	public String getGameName() {
		return gameName;
	}
	
	public void setScoreType(boolean scoreType) {
		this.scoreType = scoreType;
	}
	
	public boolean isScoreType() {
		return scoreType;
	}
	
	public Entity createEntity() {
		Entity game = new Entity(ENTITY_KIND, gameKey);
		game.setProperty(GAME_ID, gameID);
		game.setProperty(GAME_NAME, gameName);
		game.setProperty(SCORE_TYPE, scoreType);
		game.setProperty(EVENT_ID, eventID);
		
		return game;
	}

	public Key getGameKey() {
		return gameKey;
	}

	public void setEventID(int eventID) {
		this.eventID = eventID;
	}

	public int getEventID() {
		return eventID;
	}
}
