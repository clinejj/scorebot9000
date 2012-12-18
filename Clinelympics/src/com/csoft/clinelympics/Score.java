package com.csoft.clinelympics;

import java.util.Date;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Score {
	private String playerID;
	private int gameID;
	private int playerScore;
	private int eventID;
	private Key scoreKey;
	
	public static final String KEY_NAME = "scoreList";
	public static final String KEY_KIND = "Scores";
	public static final String ENTITY_KIND = "score";
	public static final String PLAYER_ID = "playerID";
	public static final String GAME_ID = "gameID";
	public static final String EVENT_ID = "eventID";
	public static final String PLAYER_SCORE = "playerScore";
	public static final String DATE = "date";

	public Score() {
		scoreKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
	}
	
	public Score(String pID, int gID, int pScore, int eID) {
		scoreKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		eventID = eID;
		playerID = pID;
		gameID = gID;
		playerScore = pScore;
	}
	
	public Score(Entity eScore) {
		scoreKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		eventID = ((Long) eScore.getProperty(EVENT_ID)).intValue();
		playerID = (String) eScore.getProperty(PLAYER_ID);
		gameID = ((Long) eScore.getProperty(GAME_ID)).intValue();
		playerScore = ((Long) eScore.getProperty(PLAYER_SCORE)).intValue();
	}

	public void setPlayerID(String playerID) {
		this.playerID = playerID;
	}

	public String getPlayerID() {
		return playerID;
	}

	public void setGameID(int gameID) {
		this.gameID = gameID;
	}

	public int getGameID() {
		return gameID;
	}

	public void setPlayerScore(int playerScore) {
		this.playerScore = playerScore;
	}

	public int getPlayerScore() {
		return playerScore;
	}
	
	public Entity createEntity() {
		Entity score = new Entity(ENTITY_KIND, scoreKey);
		score.setProperty(EVENT_ID, eventID);
		score.setProperty(PLAYER_ID, playerID);
		score.setProperty(GAME_ID, gameID);
		score.setProperty(PLAYER_SCORE, playerScore);
		score.setProperty(DATE, new Date());
		
		return score;
	}
	
	public boolean equals(Score a) {
		if (a.getPlayerID().equals(this.playerID) &&
				(a.getGameID() == this.gameID) &&
				(a.getPlayerScore() == this.playerScore) &&
				(a.getEventID() == this.eventID)) {
			return true;
		}
		return false;
	}

	public Key getScoreKey() {
		return scoreKey;
	}

	public void setEventID(int eventID) {
		this.eventID = eventID;
	}

	public int getEventID() {
		return eventID;
	}
}
