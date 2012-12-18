package com.csoft.clinelympics;

import java.util.HashMap;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Player {
	private String playerID;
	private String playerName;
	private String teamName;
	private int eventID;
	private Key playerKey;
	private HashMap<Integer, Score> scores;
	
	public static final String KEY_NAME = "playerList";
	public static final String KEY_KIND = "Players";
	public static final String ENTITY_KIND = "player";
	public static final String PLAYER_ID = "playerID";
	public static final String PLAYER_NAME = "playerName";
	public static final String EVENT_ID = "eventID";
	public static final String TEAM_NAME = "teamName";
	
	public Player() {
		playerKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		scores = new HashMap<Integer, Score>();
	}
	
	public Player(String pID, String pName, String tName, int eID) {
		playerKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		playerID = pID;
		playerName = pName;
		teamName = tName;
		eventID = eID;
		scores = new HashMap<Integer, Score>();
	}
	
	public Player(Entity pA) {
		playerID = (String) pA.getProperty(PLAYER_ID);
		playerName = (String) pA.getProperty(PLAYER_NAME);
		teamName = (String) pA.getProperty(TEAM_NAME);
		eventID = ((Long) pA.getProperty(EVENT_ID)).intValue();
		playerKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
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
		Entity player = new Entity(ENTITY_KIND, playerKey);
		player.setProperty(PLAYER_ID, playerID);
		player.setProperty(PLAYER_NAME, playerName);
		player.setProperty(TEAM_NAME, teamName);
		player.setProperty(EVENT_ID, eventID);
		
		return player;
	}

	public Key getPlayerKey() {
		return playerKey;
	}
	
	public void setPlayerKey(Key k) {
		playerKey = k;
	}

	public void setEventID(int eventID) {
		this.eventID = eventID;
	}

	public int getEventID() {
		return eventID;
	}
	
	/**
	 * Returns the given underscored_word_group as a Human Readable Word Group.
	 * (Underscores are replaced by spaces and capitalized following words.)
	 * 
	 * @param pWord
	 *            String to be made more readable
	 * @return Human-readable string
	 */
	public static String humanize(String pWord)
	{
	    StringBuilder sb = new StringBuilder();
	    String[] words = pWord.replaceAll("_", " ").split("\\s");
	    for (int i = 0; i < words.length; i++)
	    {
	        if (i > 0)
	            sb.append(" ");
	        if (words[i].length() > 0)
	        {
	            sb.append(Character.toUpperCase(words[i].charAt(0)));
	            if (words[i].length() > 1)
	            {
	                sb.append(words[i].substring(1));
	            }
	        }
	    }
	    return sb.toString();
	}
}
