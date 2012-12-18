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
	
	public static final String KEY_NAME = "eventList";
	public static final String KEY_KIND = "Events";
	public static final String ENTITY_KIND = "event";
	public static final String EVENT_ID = "eventID";
	public static final String EVENT_NAME = "eventName";
	public static final String ARCHIVED_NAME = "archived";
	public static final String MEDALS_NAME = "medals";
	public static final String ACTIVE_NAME = "active";
	public static final String TEAMSCORE_NAME = "teamscore";
	
	public Event() {
		eventKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
	}
	
	public Event(int eID, String eName, String eMedals) {
		eventKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		eventID = eID;
		eventName = eName;
		eventMedals = eMedals;
		isArchived = false;
		setActive(false);
		setTeamScore(false);
	}
	
	public Event(int eID, String eName, String eMedals, boolean arc, boolean act, boolean team) {
		eventKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		eventID = eID;
		eventName = eName;
		eventMedals = eMedals;
		isArchived = arc;
		setActive(act);
		setTeamScore(team);
	}
	
	public Event(Entity e) {
		eventKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		eventID = ((Long) e.getProperty(EVENT_ID)).intValue();
		eventName = (String) e.getProperty(EVENT_NAME);
		eventMedals = (String) e.getProperty(MEDALS_NAME);
		isArchived = (Boolean) e.getProperty(ARCHIVED_NAME);
		setActive((Boolean) e.getProperty(ACTIVE_NAME));
		setTeamScore((Boolean) e.getProperty(TEAMSCORE_NAME));
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
		Entity e = new Entity(ENTITY_KIND, eventKey);
		e.setProperty(EVENT_ID, eventID);
		e.setProperty(EVENT_NAME, eventName);
		e.setProperty(MEDALS_NAME, eventMedals);
		e.setProperty(ARCHIVED_NAME, isArchived);
		e.setProperty(ACTIVE_NAME, isActive);
		e.setProperty(TEAMSCORE_NAME, isTeamScore);
		
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
