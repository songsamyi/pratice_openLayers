<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ page session="false" %>
<!doctype html>
<html lang="en">
    <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="chrome=1">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no, width=device-width">
    <script src="/resources/js/jquery/jquery.min.js"></script>
        <script src="/resources/js/ol.js"></script>
    <link rel="stylesheet" href="/resources/css/ol.css">
    <style type="text/css">
    .map {
        width: 100%;
        height:1000px;
    }
    </style>
    <title>OpenLayer 지도|좌표확인</title>
    </head>
    <body>

    <%-- 지도표시 공간 시작 --%>
    <div id="map" class="map"></div>
    <div id="mouse-position"></div>
    <%-- 지도표시 공간 끝 --%>

    <%-- 지도 투영과 정밀도 선택 시작 --%>
    <%--
    <form>
        <label>Projection</label>
        <select id="projection">
            <option value="EPSG:4326">EPSG:4326</option>
            <option value="EPSG:3857">EPSG:3857</option>
        </select>
        <label>Precision</label>
        <input id="precision" type="number" min="0" max="12" value="4"/>
    </form>
    --%>
    <%-- 지도 투영과 정밀도 선택 끝 --%>

    <%-- 팝업컨테이너 --%>
    <div id="popup" class="ol-popup" style="background-color: white; padding: 1px 5px;">
        <a href="#" id="popup-closer" class="ol-popup-closer"></a>
        <div id="popup-content"></div>
    </div>

    <button type="button" id="makeMarker">make marker</button>
    <button type="button" id="moveMarker">move marker</button>
    <button type="button" id="deleteAllMarkers">delete all marker</button>
    <button type="button" id="deleteSelectMarkers">delete select marker</button>
    <script src="/resources/js/ol.js"></script>
    <script src="/resources/js/maker.js"></script>
    </body>
    </html>