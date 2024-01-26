/* 마우스 위치 컨트롤 생성 시작 */
var mousePositionControl = new ol.control.MousePosition({
    // 마우스 위치의 좌표를 소수점 이하 4자리까지 문자열로 표시
    coordinateFormat: ol.coordinate.createStringXY(4),
    projection: 'EPSG:4326',
    className: 'custom-mouse-position',
    // 마우스 위치 정보를 표시
    target: document.getElementById('mouse-position'),
    // 마우스 위치 정보가 정의되지 않았을 때 대체할 HTML을 설정
    undefinedHTML: '&nbsp;',
});
/* 마우스 위치 컨트롤 생성 끝 */


/* 지도 생성 시작 */
var map = new ol.Map({
    // 기본 제어 옵션에 마우스 위치 컨트롤을 추가
    controls: ol.control.defaults().extend([mousePositionControl]),
    // 지도를 렌더링할 HTML 요소를 지정
    target: 'map',
    // 지도에 추가될 레이어를 정의
    layers: [
        new ol.layer.Tile({
            source: new ol.source.OSM()
        })
    ],
    // 지도의 초기 뷰 설정을 정의
    view: new ol.View({
        projection: 'EPSG:4326',
        center: [126.9768, 37.5759],
        zoom: 18
    })
});
/* 지도 생성 끝 */



var markerArray = []; // 사용자가 입력한 정보를 저장할 배열
var markerLayer;
var feature;
var userInput
/* 버튼 클릭 시 지도에 마커 표시하기 시작 */
document.getElementById("makeMarker").addEventListener("click", () => {

    
    userInput = prompt("marker의 이름을 입력하세요.", "");
    
    if (userInput !== null) {
        alert(userInput + "를 표시할 곳을 지도에서 클릭해주세요.");
    }
    
    // 지도에 클릭 이벤트 리스너 추가
    map.once('click', function (event) {
        var coordinate = event.coordinate;
        var lonLat = ol.proj.toLonLat(coordinate);
        
        addMarker(lonLat[0], lonLat[1], userInput);
    });
    
    function addMarker(lon, lat, userInput) {
        feature = new ol.Feature({
            geometry: new ol.geom.Point(ol.proj.fromLonLat([lon, lat])),
            name: userInput
        });
        
        var markerStyle = new ol.style.Style({
            image: new ol.style.Icon({
                opacity: 1,
                scale: 1,
                src: '/resources/img/icon_cctv.png'
            }),
            zIndex: 10
        });
        
        var markerSource = new ol.source.Vector({
            features: [feature]
        });
        
        markerLayer = new ol.layer.Vector({
            source: markerSource,
            style: markerStyle
        });
        
        markerArray.push({
            name: userInput,
            feature: feature,
            layer: markerLayer
        });
        
        // 마커생성
        map.addLayer(markerLayer);
        
        console.log("Added Marker Feature:", feature.getProperties());
        console.log("Added Marker Layer:", markerLayer.getProperties());
        
        console.log(markerArray);
    }
});
/* 버튼 클릭 시 지도에 마커 표시하기 끝 */



// 팝업 오버레이 생성
const popup = new ol.Overlay({
    element: document.getElementById('popup'),
    positioning: 'bottom-center',
    stopEvent: false
});
map.addOverlay(popup);


// 맵 포인터 이벤트 리스너
map.on('pointeron', (e) => {
    const feature = map.forEachFeatureAtPixel(e.pixel, (feature) => feature);

    const precision = 4; // 표시할 소수점 이하 자릿수

    if (feature) {
        const coordinates = feature.getGeometry().getCoordinates();

        // 위도와 경도를 소수점 이하 4자리까지 문자열로 변환
        const formattedCoordinates = coordinates
            .map(coord => coord.toFixed(precision))
            .join(', ');

        const name = feature.get('name');
        const content = `<p>이름: ${name}</p><p>좌표: ${formattedCoordinates}</p>`;

        // 마커가 있는 곳에 마우스가 올려지면 커서의 스타일을 pointer로 설정
        map.getTargetElement().style.cursor = map.hasFeatureAtPixel(e.pixel) ? 'pointer' : '';

        // 팝업 내용 및 위치 설정
        popup.setPosition(coordinates);
        popup.getElement().innerHTML = content;
    } else {
        // 클릭한 피쳐가 없으면 팝업 숨기기
        popup.setPosition(undefined);
    }
});



/* 버튼 클릭 시 마커 이동하기 시작 */
document.getElementById("moveMarker").addEventListener("click", ()=>{
    
    alert("마우스로 마커를 이동시켜주세요.");
    
    // 마커를 드래그하여 이동시키기 위한 Modify interaction 추가
    var modify = new ol.interaction.Modify({
        features: new ol.Collection([feature]),
        style: null,
    });
    
    // Modify interaction 이벤트 핸들러 등록
    modify.on('modifystart', function () {
        map.getTargetElement().style.cursor = 'grabbing';
    });
    
    modify.on('modifyend', function () {
        map.getTargetElement().style.cursor = 'pointer';
    });

    // Modify interaction을 지도에 추가
    map.addInteraction(modify);
    
});
/* 버튼 클릭 시 마커 이동하기 끝 */



/* 버튼 클릭 시 모든 마커 삭제하기 시작 */
document.getElementById("deleteAllMarkers").addEventListener("click", function () {
    console.log("마커 삭제 전 배열 : ", markerArray);
    
    // 배열에 있는 모든 마커 삭제
    markerArray.forEach(function (marker) {
        var markerLayer = marker.layer;
        if (markerLayer && markerLayer.getSource) {
            var markerSource = markerLayer.getSource();
            if (markerSource) {
                markerSource.clear(); // 레이어의 모든 피처 삭제
                map.removeLayer(markerLayer); // 지도에서 레이어 제거
            }
        }
    });
    
    // 마커 배열 초기화
    markerArray = [];
    console.log("배열 삭제확인 : ", markerArray);
    alert("모든 마커를 삭제했습니다.");
});
/* 버튼 클릭 시 모든 마커 삭제하기 끝 */



/* 버튼 클릭 시 레이어 생성 시작 */

// 시작점과 끝점 좌표를 저장할 변수를 선언합니다.
var startPoint = null;
var endPoint = null;
document.getElementById("makeLayer").addEventListener("click", ()=>{
    confirm("레이어를 생성하시겠습니까?");

    alert("레이어의 시작점을 클릭해주세요.");

    // 클릭 이벤트를 추가합니다.
    map.once('click', function (e) {
        // 클릭한 지점의 좌표를 가져옵니다.
        var clickedCoordinate = e.coordinate;

        // 시작점이 설정되어 있지 않은 경우 시작점으로 설정합니다.
        if (startPoint === null) {
            startPoint = clickedCoordinate;
            alert("시작점이 설정되었습니다. 이제 다른 지점을 클릭하여 끝점을 설정하세요.");

            // 두 번째 클릭 이벤트를 등록합니다.
            map.once('click', function (e) {
                // 클릭한 지점의 좌표를 가져옵니다.
                var clickedCoordinate = e.coordinate;

                // 끝점이 설정되지 않은 경우 끝점으로 설정하고 라인을 생성합니다.
                endPoint = clickedCoordinate;
                addLayer(startPoint, endPoint);

                // 시작점과 끝점을 초기화합니다.
                startPoint = null;
                endPoint = null;
            });
        }
    });
});


function addLayer(startPoint, endPoint){
    // 라인을 생성합니다.
    var lineCoordinates = [startPoint, endPoint];
    var line = new ol.Feature({
        geometry: new ol.geom.LineString(lineCoordinates)
    });

    // 라인 스타일을 정의합니다.
    var lineStyle = new ol.style.Style({
        stroke: new ol.style.Stroke({
            color: 'blue',
            width: 10
        })
    });

    line.setStyle(lineStyle);

    // 라인을 담을 레이어를 생성합니다.
    var lineLayer = new ol.layer.Vector({
        source: new ol.source.Vector({
            features: [line]
        })
    });

    // 마커 레이어를 맵에 추가합니다.
    map.addLayer(lineLayer);
}
/* 버튼 클릭 시 레이어 생성 끝 */










