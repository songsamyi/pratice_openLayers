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

var markerArray = []; // 사용자가 입력한 정보를 저장할 배열

/* 버튼 클릭 시 지도에 마커 표시하기 시작 */
document.getElementById("makeMarker").addEventListener("click", () => {

    var userInput = prompt("marker의 이름을 입력하세요.", "");

    if (userInput !== null) {
        // 사용자가 취소 버튼을 누르지 않은 경우
        alert(userInput + "를 표시할 좌표를 지도에서 클릭해주세요.");
    }

    var feature; // 클로저 안에서 사용할 feature 변수 정의
    var markerLayer; // 클로저 안에서 사용할 markerLayer 변수 정의

    // 지도에 클릭 이벤트 리스너 추가
    map.once('click', function (event) {
        // 클릭한 위치의 좌표를 얻음
        var coordinate = event.coordinate;
        console.log("클릭된 좌표 : ", coordinate);
        // 좌표를 경도와 위도로 변환
        var lonLat = ol.proj.toLonLat(coordinate);
        console.log("경도와 위도 : ", lonLat);

        // 얻은 좌표를 이용하여 마커 추가 또는 다른 작업 수행
        addMarker(lonLat[0], lonLat[1], userInput);
    });

    function addMarker(lon, lat, name) { // 경도 위도 이름값(마커들을 구분하기위해)
        // 마커 feature 설정
        feature = new ol.Feature({
            geometry: new ol.geom.Point(ol.proj.fromLonLat([lon, lat])), // 경도 위도에 포인트 설정
            name: name
        });

        // 마커 스타일 설정
        var markerStyle = new ol.style.Style({
            image: new ol.style.Icon({ // 마커 이미지
                opacity: 1, // 투명도 1=100%
                scale: 1, // 크기 1=100%
                src: '/resources/img/icon_cctv.png'
            }),
            zIndex: 10
        });

        // 마커 레이어에 들어갈 소스 생성
        var markerSource = new ol.source.Vector({
            features: [feature] // feature의 집합
        });

        // 마커 레이어 생성
        markerLayer = new ol.layer.Vector({
            source: markerSource, // 마커 feature들
            style: markerStyle // 마커 스타일
        });

        // 클릭 가능하도록 Interaction 추가
        var selectClick = new ol.interaction.Select({
            condition: ol.events.condition.click,
            layers: [markerLayer],
            style: null
        });

        // 마커 선택 이벤트 처리
        selectClick.on('select', function (e) {
            if (e.selected.length > 0) {
                alert(name + " 선택");
            }
            if (e.deselected.length > 0) {
                alert("해제");
            }
        });

        map.addInteraction(selectClick);

        // 지도에 마커가 그려진 레이어 추가
        map.addLayer(markerLayer);

        // 배열에 좌표 정보 추가
        markerArray.push({
            name: name,
            feature: feature,
            layer: markerLayer
        });

        console.log(markerArray);
    }
});

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
