package com.csoft.clinelympics;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Event {
	private int eventID;
	private String eventName;
	private String eventMedals; //comma-separated list in order from best to worst
	private boolean isArchived;
	private boolean isActive;
	private boolean isTeamScore;
	private Key eventKey;
	
	public static final String keyName = "eventList";
	public static final String keyKind = "Events";
	public static final String entityKind = "event";
	public static final String eventIDName = "eventID";
	public static final String eventNameName = "eventName";
	public static final String archivedName = "archived";
	public static final String medalsName = "medals";
	public static final String activeName = "active";
	public static final String teamScoreName = "teamscore";
	
	public Event() {
		eventKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public Event(int eID, String eName, String eMedals) {
		eventKey = KeyFactory.createKey(keyKind, keyName);
		eventID = eID;
		eventName = eName;
		eventMedals = eMedals;
		isArchived = false;
		setActive(false);
		setTeamScore(false);
	}
	
	public Event(int eID, String eName, String eMedals, boolean arc, boolean act, boolean team) {
		eventKey = KeyFactory.createKey(keyKind, keyName);
		eventID = eID;
		eventName = eName;
		eventMedals = eMedals;
		isArchived = arc;
		setActive(act);
		setTeamScore(team);
	}
	
	public Event(Entity e) {
		eventKey = KeyFactory.createKey(keyKind, keyName);
		eventID = ((Long) e.getProperty(eventIDName)).intValue();
		eventName = (String) e.getProperty(eventNameName);
		eventMedals = (String) e.getProperty(medalsName);
		isArchived = (Boolean) e.getProperty(archivedName);
		setActive((Boolean) e.getProperty(activeName));
		setTeamScore((Boolean) e.getProperty(teamScoreName));
	}
	
	public void setEventID(int eventID) {
		this.eventID = eventID;
	}
	public int getEventID() {
		return eventID;
	}
	public void setEventName(String eventName) {
		this.eventName = eventName;
	}
	public String getEventName() {
		return eventName;
	}
	public void setEventMedals(String eventMedals) {
		this.eventMedals = eventMedals;
	}
	public String getEventMedals() {
		return eventMedals;
	}
	public void setArchived(boolean isArchived) {
		this.isArchived = isArchived;
	}
	public boolean isArchived() {
		return isArchived;
	}
	public Key getEventKey() {
		return eventKey;
	}
	
	public Entity createEntity() {
		Entity e = new Entity(entityKind, eventKey);
		e.setProperty(eventIDName, eventID);
		e.setProperty(eventNameName, eventName);
		e.setProperty(medalsName, eventMedals);
		e.setProperty(archivedName, isArchived);
		e.setProperty(activeName, isActive);
		e.setProperty(teamScoreName, isTeamScore);
		
		return e;
	}

	public void setActive(boolean isActive) {
		this.isActive = isActive;
	}

	public boolean isActive() {
		return isActive;
	}

	public void setTeamScore(boolean isTeamScore) {
		this.isTeamScore = isTeamScore;
	}

	public boolean isTeamScore() {
		return isTeamScore;
	}
}
