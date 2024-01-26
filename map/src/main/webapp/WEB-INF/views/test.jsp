<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ page session="false" %>
<html>
<head>
    <title>OSM Local Tiles</title>
    <%-- <link rel="stylesheet" href="/resources/css/style.css" type="text/css"/> --%>
    <script src="/resources/js/jquery/jquery.min.js"></script>
    <!-- bring in the OpenLayers javascript library -->
    <script src="/resources/js/OpenLayers.js"></script>
    <!-- bring in the OpenStreetMap OpenLayers layers. -->
    <script src="/resources/js/OpenStreetMap.js"></script>
 
    <script>
        var defLat=47.7;
        var defLon=7.5;
        var defZoom=10;
 
        var fodicsMap; //complex object of type OpenLayers.Map

        var cameraLayer = null;
        var cameraArray = Array(OpenLayers.Marker);

        var cameraNameArray = Array(OpenLayers.Feature.Vector);
        var cameraNameLayer = null;

        var popUpDlgGuideLineLayer = null;
        var popUpDlgGuideLineArray = Array(OpenLayers.Feature.Vector);

        var lastId;
        var nameIdx = 0;
        // var bZoomChanged = false;
        // var bLoading = false;
        
        var bMove = false;

        var bSave = true;

        function init() {
            fodicsMap = new OpenLayers.Map ("fodicsMap", {
                controls:[
                    new OpenLayers.Control.Navigation(),
                    new OpenLayers.Control.PanZoomBar(),
                    new OpenLayers.Control.ScaleLine({geodesic: true}),
                    new OpenLayers.Control.MousePosition(),                    
                    new OpenLayers.Control.Attribution()],
                maxExtent: new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34),
                maxResolution: 156543.0339,
                numZoomLevels: 19,
                units: 'm',
                projection: new OpenLayers.Projection("EPSG:900913"),
                displayProjection: new OpenLayers.Projection("EPSG:4326")
            } );
            fodicsMap.name = 'FGIS';
            var newLayer = new OpenLayers.Layer.OSM("Local Tiles", "tiles/{z}/{x}/{y}.png", {numZoomLevels: 19, alpha: true, isBaseLayer: true});
            fodicsMap.addLayer(newLayer);
                var switcherControl = new OpenLayers.Control.LayerSwitcher();
                fodicsMap.addControl(switcherControl);
                switcherControl.maximizeControl();

            if( ! fodicsMap.getCenter() ){
                var lonLat = new OpenLayers.LonLat(defLon, defLat).transform(new OpenLayers.Projection("EPSG:4326"), fodicsMap.getProjectionObject());
                lonLat.lon = 14127472.612954;
                lonLat.lat = 4506981.684082;
                defZoom = 17;
                fodicsMap.setCenter (lonLat, defZoom);
            }

            fodicsMap.events.register("movestart", fodicsMap, moveStartFunc);            
            fodicsMap.events.register("moveend", fodicsMap, moveEndFunc);            
            fodicsMap.events.register("zoomend", fodicsMap, zoomEndFunc);

            popUpDlgGuideLineLayer = new OpenLayers.Layer.Vector('POPUP_DLG_GUIDE_LINE');
            popUpDlgGuideLineLayer.layerName = 'POPUP_DLG_GUIDE_LINE';

            cameraLayer = new OpenLayers.Layer.Markers('CAMERA');
            cameraLayer.layerName = 'CAMERA';

            var cameraNameStyle = new OpenLayers.StyleMap({
                'default' : new OpenLayers.Style(OpenLayers.Util.applyDefaults({
                    // externalGraphic : "{imgPath}", // 아이콘 표시
                    // graphicWidth: 40, graphicHeight: 40, graphicYOffset: -40,
                    // graphicOpacity : 1,
                    // 라벨 표시, {} 사이에 feature의 attribute를 참조할 수 있음﻿ 
                    label : "{title}", 
                    fontColor: "{fColor}",
                    fontSize: "{fSize}",
                    fontFamily: "맑은고딕",
                    fontWeight: "bold",
                    labelXOffset: 0,
                    labelYOffset: 0,
                    labelOutlineColor: "{olColor}",
                    labelOutlineWidth: 3,
                    labelXOffset : 0,
                    labelYOffset : -5
                }))
            }); 

            cameraNameLayer = new OpenLayers.Layer.Vector("CAMERA_NAME", {styleMap: cameraNameStyle});
            cameraNameLayer.layerName = 'CAMERA_NAME';

            fodicsMap.addLayer(popUpDlgGuideLineLayer);
            fodicsMap.addLayer(cameraNameLayer);
            fodicsMap.addLayer(cameraLayer);

            initGisEvent();

            displayPosition();

            setTrashIcon(1);
        }

        function checkLayer(){
            console.log(cameraLayer);
            console.log(cameraNameLayer);
        }

        function setTrashIcon(bShow) {
            var trashId = 'trash';
            if(bShow == 1){
                bnd = fodicsMap.calculateBounds();
                var left = bnd.left;
                var top = bnd.top;
                var right = bnd.right;
                var x = left + (right - left) / 2;
                var y = top;
                
                var newLonLat = new OpenLayers.LonLat(x, y);
                var px = fodicsMap.getPixelFromLonLat(newLonLat);
                px.y = px.y + 50;
                var lonLat = fodicsMap.getLonLatFromPixel(px);

                // var lonLat = new OpenLayers.LonLat(x, y);
                var size = new OpenLayers.Size(40,40);
                var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
                var imgPath = '/resources/img/trash.png';

                var icon = new OpenLayers.Icon(imgPath, size, offset);  
                var trashMarker = new OpenLayers.Marker(lonLat, icon);   

                trashMarker.markerId = trashId;
                trashMarker.type = 'TRASH';
                
                trashMarker.events.register("select", trashMarker, function(e){
                    responseMessage('hover', msg);
                });
                
                trashMarker.events.register("mousedown", trashMarker, function(e){
                    responseMessage('mousedown', '');
                });
                
                trashMarker.events.register("mouseup", trashMarker, function(e){
                    if(bMove == true){
                        bMove = false;
                        var msg = trashMarker.markerId;
                        msg += ','
                        msg += e.x;
                        msg += ','
                        msg += e.y;
                        msg += ','
                        responseMessage('mouseup', msg);
                    }
                });
                
                cameraLayer.addMarker(trashMarker);
                cameraArray.push(trashMarker);

            }
            else{                
                var trashMarker = null;
                var removeIdx = 0;
                var bFind = 0;

                while(true){
                    if(removeIdx == cameraArray.length){
                        break;
                    }

                    if(cameraArray[removeIdx].markerId == trashId){
                        bFind = 1;
                        trashMarker = cameraArray[removeIdx];
                        responseMessage(trashMarker.markerId, removeIdx);
                        break;
                    }
                    removeIdx++;
                }
                
                if(bFind == 1)
                {
                    cameraLayer.removeMarker(trashMarker);
                    cameraArray.splice(removeIdx, 1);
                }
            }
        }

        function displayPosition() {

//            hideAllCameraGuideLine()

            bnd = fodicsMap.calculateBounds();
            var left = bnd.left;
            var top = bnd.top;
            var right = bnd.right;
            var bottom = bnd.bottom;
//            alert(apiMap.getCenter());
            var centerX = fodicsMap.getCenter().lon;
            var centerY = fodicsMap.getCenter().lat;

            var zoom = fodicsMap.getZoom();

            var msg = left;
            msg += ','
            msg += top;
            msg += ','
            msg += right;
            msg += ','
            msg += bottom;
            msg += ','
            msg += centerX;
            msg += ','
            msg += centerY;
            msg += ','
            msg += zoom;
            msg += ','
//            alert(msg);
            responseMessage('displayPosition', msg);
        }

        function moveStartFunc(e) {
            hideAllCameraGuideLine();
            setTrashIcon(0);
            responseMessage('moveStart', '');
            // if(e.bZoomChanged){
            // }
            // else{
            // }
        }

        function moveEndFunc(e) {
            showAllCameraGuideLine();
            setTrashIcon(1);
            displayPosition();
            // responseMessage('moveend', '');

            // if(e.bZoomChanged){
            // }
            // else{
            // }
        }

        function zoomEndFunc(e) {
            changeGateIconSize();
            responseMessage('zoomEndFunc', '');
            // console.log("zoomend");
        }

        function responseMessage(cmd, msg) {
            console.log(cmd, msg);
//            external.responseMessage(cmd, msg);
        }

        function addCameraIcon(cameraId, lon, lat, cameraName, nStatus){
            var lonLat = new OpenLayers.LonLat(lon, lat);
            cameraId = cameraId + nameIdx;
            nameIdx++;

            var width = 40 - (18 - fodicsMap.getZoom()) * 2;
            var size = new OpenLayers.Size(width,width);
            var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
            var imgPath = '/resources/img/icon_cctv.png';
            
            if(nStatus == -1){
                imgPath = '/resources/img/icon_cctv.png';
            }
            else if(nStatus == 0){
                imgPath = '/resources/img/icon_cctvGateClose.png';
            }
            else if(nStatus == 1){
                imgPath = '/resources/img/icon_cctvGateOpen.png';
            }
            else if(nStatus == 2){
                imgPath = '/resources/img/icon_cctvGateClose_Inactive.png';
            }
            else{
                imgPath = '/resources/img/icon_cctvGateOpen.png';
            }

            var icon = new OpenLayers.Icon(imgPath, size, offset);  
            var cameraMarker = new OpenLayers.Marker(lonLat, icon);   


            cameraMarker.markerId = cameraId;
            lastId = cameraId;
            cameraMarker.name = cameraName;
            cameraMarker.status = nStatus;
            cameraMarker.imgPath = imgPath;
            cameraMarker.type = 'CAMERA';
            cameraMarker.events.register("dblclick", cameraMarker, function(e){
                responseMessage('cameraDbClick', cameraMarker.markerId);
//                alert(marker.markerId + " " + marker.name);
            });
            
            cameraMarker.events.register("mousedown", cameraMarker, function(e){
                bMove = true;
                var msg = cameraMarker.markerId;
                msg += ','
                msg += e.x;
                msg += ','
                msg += e.y;
                msg += ','
                responseMessage('mouseDown', msg);
            });
            
            cameraLayer.addMarker(cameraMarker);
            if(bSave == true){
                cameraArray.push(cameraMarker);
            }

            addCameraName(cameraId, lon, lat, cameraName);

            return cameraMarker.markerId;
        }

        function addCameraName(cameraId, lon, lat, cameraName){
            cameraId = 'N' + cameraId;
            var lonLat = new OpenLayers.LonLat(lon, lat);            
            var cameraNamePos = new OpenLayers.Geometry.Point(lon, lat);
            var cameraNameFeat = new OpenLayers.Feature.Vector(cameraNamePos);
            cameraNameFeat.id = cameraId;
            cameraNameFeat.attributes.title = cameraName;
            cameraNameFeat.attributes.fColor = "black";
            cameraNameFeat.attributes.fSize = "11px";
            cameraNameFeat.attributes.olColor = "black";
            cameraNameLayer.addFeatures([cameraNameFeat]);
            cameraNameArray.push(cameraNameFeat);
            console.log(cameraNameFeat.id);
        }

        function removeCameraIcon(cameraId){
            var cameraMarker = null;
            var removeIdx = 0;
            var bFind = 0;

            while(true){
                if(removeIdx == cameraArray.length){
                    break;
                }

                if(cameraArray[removeIdx].markerId == cameraId){
                    bFind = 1;
                    cameraMarker = cameraArray[removeIdx];
                    break;
                }
                removeIdx++;
            }
            
            if(bFind == 1)
            {
                cameraLayer.removeMarker(cameraMarker);
                cameraArray.splice(removeIdx, 1);

                reomveCameraName(cameraId);
            }

            return cameraMarker;
        }

        function reomveCameraName(cameraId){
            cameraId = 'N' + cameraId;
            var cameraNameFeat = null;
            var removeIdx = 0;
            var bFind = 0;

            while(true){
                if(removeIdx == cameraNameArray.length){
                    break;
                }
                cameraNameFeat = cameraNameArray[removeIdx];
                console.log(removeIdx, cameraNameFeat);
                if(cameraNameFeat.id == cameraId){
                    bFind = 1;
                    break;
                }
                removeIdx++;
            }
            
            if(bFind == 1)
            {
                cameraNameLayer.removeFeatures(cameraNameFeat);
                cameraNameArray.splice(removeIdx, 1);
            }

            return cameraNameFeat;
        }

        function moveCameraIcon(cameraId, lon, lat, cameraName, nStatus){
            removeCameraIcon(lastId);
            addCameraIcon(lastId, lon, lat, cameraName, nStatus);
        }

        function changeGateIcon(gateId, nStatus){
            var marker = removeCameraIcon(gateId);
            addCameraIcon(gateId, marker.lonlat.lon, marker.lonlat.lat, marker.name, nStatus);
            return markerId;
        }

        function removeAllCamera(){
            cameraLayer.removeAllMarkers();
        }
        
        function changeGateIconSize(){
            var idx = 0;
            var bFind = 0;

            cameraLayer.setOpacity(0);
            while(true){
                if(idx == cameraLayer.markers.length){
                    break;
                }

                if(cameraLayer.markers[idx].type == 'CAMERA'){
                    cameraLayer.removeMarker(cameraLayer.markers[idx]);
                }                
                idx++;
            }

            idx = 0;
            bSave = false;
                console.log(idx, cameraArray.length);
            while(true){
                if(idx < 10){
                    console.log(idx, cameraArray.length);
                }
                if(idx == cameraArray.length){
                    break;
                }

                // console.log(idx, cameraArray[idx]);
                if(cameraArray[idx].type == 'CAMERA'){
                    var cameraMarker = cameraArray[idx];
                    var cameraId = cameraMarker.markerId;
                    var cameraName = cameraMarker.name;
                    var status = cameraMarker.status;
                    var lonLat = cameraMarker.lonlat;
                    addCameraIcon(cameraId, lonLat.lon, lonLat.lat, cameraName, status);
                }                
                idx++;
            }
            bSave = true;

            cameraLayer.setOpacity(1);
            cameraLayer.redraw();
            // while(true){
            //     if(idx == cameraArray.length){
            //         break;
            //     }

            //     if(cameraArray[idx].markerId != 'trash' && cameraArray[idx].markerId != undefined){
            //         console.log(cameraArray[idx].markerId);
            //         var cameraFeat = cameraArray[idx];
            //         console.log(cameraFeat);
            //         console.log(fodicsMap.getZoom());
            //         cameraLayer.removeMarker(cameraFeat);
                    
            //         var lonLat = cameraFeat.lonlat;
            //         var width = fodicsMap.getZoom() + 22;
            //         var size = new OpenLayers.Size(width,width);
            //         var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
            //         var cameraId = cameraFeat.markerId;
            //         var cameraName = cameraFeat.name;
            //         var imgPath = cameraFeat.imgPath;
            //         var icon = new OpenLayers.Icon(imgPath, size, offset);
                    
            //         var cameraMarker = new OpenLayers.Marker(lonLat, icon);   
            //         cameraMarker.markerId = cameraId;
            //         cameraMarker.name = cameraName;
            //         cameraMarker.imgPath = imgPath;

            //         console.log(cameraMarker);
            //         cameraMarker.events.register("dblclick", cameraMarker, function(e){
            //             responseMessage('cameraDbClick', cameraMarker.markerId);
            //         //                alert(marker.markerId + " " + marker.name);
            //         });

            //         cameraMarker.events.register("mousedown", cameraMarker, function(e){
            //             bMove = true;
            //             var msg = cameraMarker.markerId;
            //             msg += ','
            //             msg += e.x;
            //             msg += ','
            //             msg += e.y;
            //             msg += ','
            //             responseMessage('mouseDown', msg);
            //         });

            //         cameraLayer.addMarker(cameraMarker);
            //     }

            //     idx++;
            // }

            console.log(cameraArray.length);
            console.log( cameraLayer.markers.length);
            
            // if(bFind == 1)
            // {
            //     cameraLayer.removeMarker(cameraMarker);
            //     cameraArray.splice(removeIdx, 1);

            //     reomveCameraName(cameraId);
            // }

        }
        
        function addCameraGuideLine(cameraId, x1, y1, x2, y2) {    
            cameraId = 'L' + cameraId;
            var points = new Array(
                new OpenLayers.Geometry.Point(x1, y1),
                new OpenLayers.Geometry.Point(x2, y2)
            );

            var line = new OpenLayers.Geometry.LineString(points);
            var popUpDlgGuideLineFeat= new OpenLayers.Feature.Vector(line, null, {
                strokeColor: '#7DE1FF',
                strokeWidth: 5.0,
                strokeOpacity: 1
            });

            popUpDlgGuideLineFeat.id = cameraId;
            popUpDlgGuideLineLayer.addFeatures([popUpDlgGuideLineFeat]);
            popUpDlgGuideLineArray.push(popUpDlgGuideLineFeat);
        }

        function removeCameraGuideLine(cameraId) {            
            cameraId = 'L' + cameraId;
            var popUpDlgGuideLineFeat = null;
            var removeIdx = 0;
            
            while(true){
                if(removeIdx == popUpDlgGuideLineArray.length){
                    break;
                }

                if(popUpDlgGuideLineArray[removeIdx].id == cameraId){
                    bFind = 1;
                    popUpDlgGuideLineFeat = popUpDlgGuideLineArray[removeIdx];
                    break;
                }
                removeIdx++;
            }
            
            if(bFind == 1)
            {
                popUpDlgGuideLineLayer.removeFeatures(popUpDlgGuideLineFeat);
                popUpDlgGuideLineArray.splice(removeIdx, 1);
            }

            return popUpDlgGuideLineFeat;
        }

        function editCameraGuideLine(cameraId, x1, y1, x2, y2) {            
            removeCameraGuideLine(cameraId, 1);
            addCameraGuideLine(cameraId, x1, y1, x2, y2, 1);
        }

        function showAllCameraGuideLine() {
            popUpDlgGuideLineLayer.setOpacity(1);
            // vectorLayer.redraw();
        }
        
        function hideAllCameraGuideLine() {
            popUpDlgGuideLineLayer.setOpacity(0);
            // var idx = 0;
            // var feat = null;

            // while(true){
            //     if(idx == lineArray.length){
            //         break;
            //     }

            //     feat = lineArray[idx];
            //     vectorLayer.eraseFeatures(feat);

            //     idx++;
            // }
        }
        
        function setCenterAndZoom(centerX, centerY, zoom) {
            var lonLat = new OpenLayers.LonLat(centerX, centerY);
            fodicsMap.setCenter (lonLat, zoom);
            // responseMessage('setCenterAndZoom', '');
            displayPosition();
        }

        function initGisEvent() {
            // apiMap.events.listeners.mousedown.unshift({
            //     func: mouseDownEvent
            // });

            fodicsMap.events.listeners.mousemove.unshift({
                func: mouseMoveFunc
            });

            fodicsMap.events.listeners.mouseup.unshift({
                func: mouseUpFunc
            });
            // addClickEvent();
        }
        
        function mouseMoveFunc(evt) {
            if(bMove == false){
                return;
            }

            var msg = evt.xy.x;
            msg += ',';
            msg += evt.xy.y;
            msg += ',';
            responseMessage('mouseMove', msg);
        }

        function mouseUpFunc(evt) {
            if(bMove == false){
                return;
            }

            bMove = false;

            var msg = evt.x;
            msg += ',';
            msg += evt.y;
            msg += ',';
            responseMessage('mouseUp', msg);
        }

        function hideCameraGuideLine(cameraId) {
            cameraId = 'L' + cameraId;
            var idx = 0;            
            console.log(popUpDlgGuideLineLayer.features.length);
            while(true){
                if(popUpDlgGuideLineLayer.features.length == idx){
                    break;
                }

                console.log(popUpDlgGuideLineLayer.features[idx].id);
                if(popUpDlgGuideLineLayer.features[idx].id == cameraId){
                    popUpDlgGuideLineLayer.features[idx].style.strokeOpacity = 0;
                    console.log(popUpDlgGuideLineLayer.features[idx].style.strokeOpacity);
                }

                idx++;
            }
            popUpDlgGuideLineLayer.redraw();
        }

        function setMarkPopUpDlg(cameraId, bShow){
            if(bShow == 1){
                var idx = 0;
                while(true){
                    if(idx == cameraLayer.markers.length){
                        break;
                    }

                    if(cameraLayer.markers[idx].markerId == cameraId && cameraLayer.markers[idx].markerId != 'trash'){                        
                        console.log(cameraLayer.markers[idx]);
                        var lonLat = cameraLayer.markers[idx].lonlat;
                        var width = (42 - (18 - fodicsMap.getZoom()) * 2);
                        var height = width * 26 / 42;
                        var size = new OpenLayers.Size(width,height);

                        var cameraWidth = 40 - (18 - fodicsMap.getZoom()) * 2;
                        var cameraSize = new OpenLayers.Size(cameraWidth,cameraWidth);

//                        var offset = new OpenLayers.Pixel(-(cameraSize.w/2), -cameraSize.h);
                        var offset = new OpenLayers.Pixel(-(size.w/2), size.h * 2 / 3);
                        var imgPath = '/resources/img/videoHide.gif';
                        var icon = new OpenLayers.Icon(imgPath, size, offset);  
                        var marker = new OpenLayers.Marker(lonLat, icon);   

                        marker.markerId = 'P' + cameraId;
                        marker.type = 'POPUP_DLG_MARK';
                        marker.imgPath = imgPath;

                        cameraLayer.addMarker(marker);
                        break;
                    }
                    idx++;
                }
            }
            else{
                var idx = 0;
                var markerId = 'P' + cameraId;
                while(true){
                    if(idx == cameraLayer.markers.length){
                        break;
                    }

                    var marker = null;
                    
                    if(cameraLayer.markers[idx].type == 'POPUP_DLG_MARK'){                    
                        if(cameraLayer.markers[idx].markerId == markerId && cameraLayer.markers[idx].markerId != 'trash'){
                            marker = cameraLayer.markers[idx];
                            break;
                        }
                    }

                    idx++;
                }

                if(marker != null){
                    cameraLayer.removeMarker(marker);
                }
            }
        }

        
        
    </script>
</head>
 
<!-- body.onload is called once the page is loaded (call the 'init' function) -->
<body onload="init()"><!--</body> oncontextmenu="return false">-->
 
    <!-- define a DIV into which the map will appear. Make it take up the whole window -->
    <div style="width:100%; height:80%" id="fodicsMap"></div>
 
    <div id="desc" style="padding:5px 0 0 5px;">
        <button type="button" onclick="javascript:addCameraGuideLine('test', 14127472.612954, 4506981.684082, 1000, 1000, 1);" name="addpin">addCameraGuideLine</button>
        <button type="button" onclick="javascript:editCameraGuideLine('test', 14127472.612954, 4506981.684082, 14128472.612954, 4507981.684082, 1, 1);" name="addpin">editCameraGuideLine</button>
        <button type="button" onclick="javascript:removeCameraIcon('test');" name="addpin">removeCameraIcon</button>
        <button type="button" onclick="javascript:addCameraIcon('test', 14127472.612954, 4506981.684082, 'test', 3);" name="addpin">addCameraIcon</button>
        <button type="button" onclick="javascript:changeGateIcon('test', 2);" name="addpin">changeGateIcon</button>
        <button type="button" onclick="javascript:moveCameraIcon('test', 14127402.612954, 4506981.684082, 'test', 0);" name="addpin">moveCameraIcon</button>
        <button type="button" onclick="javascript:setTrashIcon(0);" name="addpin">setTrashIcon 0</button>
        <button type="button" onclick="javascript:hideCameraGuideLine('test');" name="addpin">hideCameraGuideLine</button>
        <button type="button" onclick="javascript:setMarkPopUpDlg('test', 1);" name="addpin">setMarkPopUpDlg 1</button>
        <button type="button" onclick="javascript:removeAllCamera();" name="addpin">removeAllCamera</button>
        <button type="button" onclick="javascript:checkLayer();" name="addpin">checkLayer</button>
        
    </div>
 
</body>
 
</html>