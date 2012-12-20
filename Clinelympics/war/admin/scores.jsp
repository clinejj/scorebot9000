<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Score" %>
<%@ page import="com.csoft.clinelympics.Settings" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<%
	DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
	Key settingsKey = KeyFactory.createKey(Settings.KEY_KIND, Settings.KEY_NAME);
	Query query = new Query(Settings.ENTITY_KIND, settingsKey);
	List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	if (!settings.isEmpty()) {
		Settings s = new Settings(settings.get(0));
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();
		if (user != null) {
			if (user.getNickname().equals(s.getAdmin())) {
				pageContext.setAttribute("idval", Score.PLAYER_ID);
				pageContext.setAttribute("nameval", Score.GAME_ID);
				pageContext.setAttribute("scoreval", Score.PLAYER_SCORE);
				pageContext.setAttribute("eventval", Score.EVENT_ID);
				pageContext.setAttribute("user_email", s.getAdmin()); 
				pageContext.setAttribute("type_val", Score.ENTITY_KIND);
		%>
    <div id="score_response"></div>
    <div id="score_form">
    <form action="" id="addScoreForm" class="form-inline">
      Event ID: <input type="text" name="${fn:escapeXml(eventval)}" maxlength="3" size="3"/>
      Game ID: <input type="text" name="${fn:escapeXml(nameval)}" maxlength="3" size="3"/>
      Player ID: <input type="text" name="${fn:escapeXml(idval)}" maxlength="10" size="10"/>
      Score: <input type="text" name="${fn:escapeXml(scoreval)}" />
      <input type="hidden" value="${fn:escapeXml(user_email)}" id="userEmail"/>
    	<input type="hidden" id="scoreType" name="type" value="${fn:escapeXml(type_val)}" />
      <input type="submit" value="Add" class="btn btn-primary"/>
    </form>
    </div>
  <div id="score_table">
<%
    Key scoreKey = KeyFactory.createKey(Score.KEY_KIND, Score.KEY_NAME);
    query = new Query(Score.ENTITY_KIND, scoreKey).addSort(Score.DATE, Query.SortDirection.DESCENDING);
    List<Entity> scores = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (scores.isEmpty()) {
        %>
        <div class="alert alert-error">There are no scores</div>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr id="header"><th>Date</td><th>EventID</th><th>GameID</th><th>PlayerID</th><th>PlayerScore</th><th width="80px"></th></tr></thead>
        <tbody>
        <%
        for (Entity score : scores) {
            pageContext.setAttribute("player_id", score.getProperty(Score.PLAYER_ID));
						pageContext.setAttribute("game_id", score.getProperty(Score.GAME_ID));
						pageContext.setAttribute("player_score", score.getProperty(Score.PLAYER_SCORE));
						pageContext.setAttribute("event_id", score.getProperty(Score.EVENT_ID));
						pageContext.setAttribute("date", score.getProperty(Score.DATE));
						pageContext.setAttribute("name_enc", "id" + score.getProperty(Score.PLAYER_ID) + score.getProperty(Score.GAME_ID) + score.getProperty(Score.EVENT_ID));
						pageContext.setAttribute("delete_vals", "" + Score.PLAYER_ID + "=" + score.getProperty(Score.PLAYER_ID) + "&" + Score.GAME_ID + "=" + score.getProperty(Score.GAME_ID) + "&" + Score.EVENT_ID + "=" + score.getProperty(Score.EVENT_ID));
						%>
            <tr id="${fn:escapeXml(name_enc)}">
            <td>${fn:escapeXml(date)}</td>
            <td>${fn:escapeXml(event_id)}</td>
            <td>${fn:escapeXml(game_id)}</td>
            <td>${fn:escapeXml(player_id)}</td>
            <td>${fn:escapeXml(player_score)}</td>
            <td width="80px"><div> <button id="del_${fn:escapeXml(name_enc)}" class="btn btn-danger" onClick="deleteItem('${fn:escapeXml(delete_vals)}', '${fn:escapeXml(type_val)}');" style="display:none;">Delete</button></div></td>
			</tr>
            <%
        }
    }
%>
</tbody>
	</table>
  </div>
    <%
			}
		}
	}
	%>
	<script type="application/javascript" src="js/table-magic.js"></script>