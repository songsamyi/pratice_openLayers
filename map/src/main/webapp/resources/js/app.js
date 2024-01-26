
/*
var sql = require('mssql');

var config = {
    user: 'sa',
    password: 'j$b!c&1',
    database: 'FdcVmsDB',
    server: '127.0.0.1',
    options: {
        encrypt: true,
        trustServerCertificate: false,
        enableArithAbort: true
    }
};
sql.connect(config, function(err) {
    if( err ) 
        return console.error('sql connect error : ', err);

    console.log('MSSQL 연결 완료');
});
*/

var http = require('http');
//var fs = require('fs');
var express = require('express');
var app = express();

//var exePath = "C:/web/data/GetDashBoardData.exe";
var exePath = "./data/GetDashBoardData.exe";

/*
app.use('/script', express.static(__dirname + '/script'));
app.use('/css', express.static(__dirname + '/css'));
app.use('/img', express.static(__dirname + '/img'));
app.use('/js', express.static(__dirname + '/js'));
app.use('/font', express.static(__dirname + '/font'));
*/

app.use('/', express.static(__dirname + '/'));

var server = http.createServer(app).listen(8888, function() {
    console.log('Server Running...');
});

// 트랜잭션 쿼리
var transactionQuery = "";

// 사용자 정보
app.get('/selectUserInfo', function(req, res) 
{
    console.log('Get /selectUserInfo');

    var query = "SELECT * FROM TB_AI_NVR_DASH_BOARD_USER";

    executeExeFile(exePath, query, 'selectUserInfo', res);
});

app.get('/updateUserInfo', function(req, res) 
{
    console.log('Get /updateUserInfo');

    var query = "UPDATE TB_AI_NVR_DASH_BOARD_USER SET ";
    query += "user_pw='" + req.query.user_pw + "', ";
    query += "user_backup=" + req.query.user_backup + ", ";
    query += "user_status=" + req.query.user_status + ") ";
    query += "WHERE user_id='" + req.query.user_id + "')";
    executeExeFile(exePath, query, 'updateUserInfo', res);
});

app.get('/insertUserInfo', function(req, res) 
{
    console.log('Get /insertUserInfo');

    var query = "INSERT INTO TB_AI_NVR_DASH_BOARD_USER VALUES (";
    query += "'" + req.query.id + "', ";    // user_id
    query += "'" + req.query.pw + "', ";    // user_pw 
    query += "'" + req.query.name + "', ";  // user_name
    query += req.query.backup + ", ";       // user_backup
    query += req.query.status + ");";       // user_status
    executeExeFile(exePath, query, 'insertUserInfo', res);
});

app.get('/deleteUserInfo', function(req, res) 
{
    console.log('Get /deleteUserInfo');

    var query = "DELETE FROM TB_AI_NVR_DASH_BOARD_USER WHERE ";

    // &으로 Array인지 Object인지 구분
    if( req.url.includes('&') )
    {
        for( var i=0; i<req.query.id.length; i++ )
        {
            query += ("user_id='" + req.query.id[i] + "'");

            if( i != (req.query.id.length-1) )
                query += " OR ";
        }
    }    
    else
        query += "user_id='" + req.query.id + "'";

    executeExeFile(exePath, query, 'deleteUserInfo', res);
});

// 카메라
app.get('/selectCamera', function(req, res) 
{
    console.log('Get /selectCamera');

    var query = 'SELECT camera_code, camera_name FROM TB_CAMERA';

    executeExeFile(exePath, query, 'selectCamera', res);
});

// 사용자 그룹설정
app.get('/selectCameraDef', function(req, res) 
{
    console.log('Get /selectCameraDef');

    var query = "SELECT * FROM TB_AI_CAMERA_GROUP_DEF WHERE user_id = '" + req.query.userId + "'";

    executeExeFile(exePath, query, 'selectCameraDef', res);
});

app.get('/updateCameraDef', function(req, res) 
{
    console.log('Get /updateCameraDef');

    var query = "UPDATE TB_AI_CAMERA_GROUP_DEF SET ";
    query += "ai_group_name='" + req.query.groupName + "' ";
    query += "WHERE ai_group_code='" + req.query.groupCode + "';";

    transactionQuery += query;
    
    res.send();
});

app.get('/insertCameraDef', function(req, res) 
{
    console.log('Get /insertCameraDef');    

    var query = "INSERT INTO TB_AI_CAMERA_GROUP_DEF VALUES (";
    query += "'" + req.query.groupName + "', "; // ai_group_name
    query += "'1', "; // ai_group_use
    query += "0, "; // georef
    query += "'" + req.query.userId + "', "; // user_id
    query += "'" + req.query.userName + "') SELECT @@IDENTITY AS no;"; // user_name

    executeExeFile(exePath, query, 'insertCameraDef', res);

    //transactionQuery += query;
});

app.get('/deleteCameraDef', function(req, res) 
{
    console.log('Get /deleteCameraDef');

    // TB_AI_CAMERA_GROUP_DEF
    var query = "DELETE FROM TB_AI_CAMERA_GROUP_DEF WHERE ";
    query += "ai_group_code='" + req.query.groupCode + "';";
    transactionQuery += query;

    // TODO
    // TB_AI_CAMERA_GROUP_REG
    query = "DELETE FROM TB_AI_CAMERA_GROUP_REG WHERE ";
    query += "ai_group_code='" + req.query.groupCode + "';";
    transactionQuery += query;

    res.send();
});

app.get('/selectCameraReg', function(req, res) 
{
    console.log('Get /selectCameraReg');

    var query = "SELECT * FROM TB_AI_CAMERA_GROUP_REG WHERE user_id = '" + req.query.userId + "'";

    executeExeFile(exePath, query, 'selectCameraReg', res);
});
app.get('/updateCameraReg', function(req, res) 
{
    console.log('Get /updateCameraReg');
});
app.get('/insertCameraReg', function(req, res) 
{
    console.log('Get /insertCameraReg');

    var query = "INSERT INTO TB_AI_CAMERA_GROUP_REG VALUES (";
    query += "'" + req.query.groupCode + "', "; // ai_group_code
    query += "'" + req.query.siteCode + "', "; // site_code
    query += "'" + req.query.cameraCode + "', "; // camera_code
    query += "'" + req.query.cameraName + "', "; // camera_name
    query += "0, "; // camera_type
    query += "0, "; // georef
    query += "'" + req.query.userId + "');"; // user_id

    transactionQuery += query;

    res.send();
});
app.get('/deleteCameraReg', function(req, res) 
{
    console.log('Get /deleteCameraReg');

    var query = "DELETE FROM TB_AI_CAMERA_GROUP_REG WHERE ";
    query += "ai_group_code='" + req.query.groupCode + "' AND ";
    query += "camera_code='" + req.query.cameraCode + "'; ";

    transactionQuery += query;

    res.send();
});

app.get('/executeTransaction', function(req, res) 
{
    console.log('Get /executeTransaction');

    executeExeFile(exePath, transactionQuery, 'executeTransaction', res);
    transactionQuery = "";
});

app.get('/getBackDateValue', function(req, res)
{
    console.log('Get /getBackDateValue');
    console.log(req.query.startDate);         
    //executeExeFile_day("C:/web/data/GetDashBoardData.exe","du", req.query.startDate, req.query.startDate, res);    
    executeExeFile_day("./data/GetDashBoardData.exe","du", req.query.startDate, req.query.startDate, res);    
});

// 湲곌컙 �뜲�씠�꽣
app.get('/getDurationValue', function(req, res) 
{
    console.log('Get /getDurationValue');
    console.log(req.query.startDate);
    console.log(req.query.endDate);
    //executeExeFile_day("C:/web/data/GetDashBoardData.exe","du", req.query.startDate, req.query.endDate, res);    
    executeExeFile_day("./data/GetDashBoardData.exe","du", req.query.startDate, req.query.endDate, res);    
});

app.get('/getEachDateValue', function(req, res) 
{
    console.log('Get /getEachDateValue');
    console.log(req.query.Date1);
    console.log(req.query.Date2);
    //executeExeFile_day("C:/web/data/GetDashBoardData.exe","dw", req.query.Date1, req.query.Date2, res);    
    executeExeFile_day("./data/GetDashBoardData.exe","dw", req.query.Date1, req.query.Date2, res);    
});

/*
    
    암호화 및 인코딩 !!!!
*/
app.get('/login', function(req, res) 
{
    console.log('Get /login');
    
    var query = "SELECT user_status, user_name FROM TB_AI_NVR_DASH_BOARD_USER WHERE user_id='" + req.query.id + "' AND user_pw='" + req.query.pw + "'";
    executeExeFile(exePath, query, 'login', res);
});

/*
    순서
    writeIniFile(query, res) -> executeExeFile(filePath, query, res) -> readJsonFile(filePath, res)
*/

//  환경설정 저장
app.get('/saveConfigValue', function(req, res) 
{
    console.log('Set /saveConfigValue');

    var man_obj = new Array;
    var ajson = new Object();			
	ajson.init_page = req.query.init_page;    
    ajson.divide_page = req.query.divide;	
    ajson.exe_type = req.query.exe_type;	
    
	man_obj.push(ajson);

    const makeJSON = JSON.stringify(man_obj);
    console.log(makeJSON);
    var makefile = 'config_data ='  + makeJSON ;

    var writeFile = require('fs');
    var iniFilePath = './dashboard_config.json';   
    writeFile.writeFileSync(iniFilePath, makefile);


    var readFile = require('fs');
    readFile.readFile(iniFilePath, 'utf8', function(readError, readData) {
        res.send(readData);
    });

});

// Query를 받아서 INI 파일에 쓰기
function writeIniFile(query, fileName, res)
{
    var writeFile = require('fs');
    var iniFilePath = 'D:/Project_HTML/AI_VINUS_Dashboard/GetDashBoardData/reqQuery.ini';

    // Ini에 쿼리 작성
    writeFile.writeFile(iniFilePath, query, 'utf8', function(writeError, readError) {
        executeExeFile(exePath, query, fileName, res);
    });
}

// GetDashBoardData 파일을 실행한다.
function executeExeFile(exePath, query, fileName, res)
{
    var {execFile} = require('child_process');
    var resultFile = fileName + '.json';

    console.log('[executeExeFile] ' + query);

    // GetDashBoardData 파일 실행
    //const child = execFile(exePath, ['dq', query, '172.16.105.203', resultFile], (error, stdout, stderr) => {
    const child = execFile(exePath, ['dq', query, '127.0.0.1', resultFile], (error, stdout, stderr) => {
        if( error )
        {
            console.log(stderr);
            throw error;
        }

        //console.log(stdout);

        // 에러가 없음 => 정상
        //if( stderr == null || stderr == '' )
        //{
            var filePath = 'C:/web/data/' + resultFile;
            //var filePath = './data/' + resultFile;
            readJsonFile(filePath, res);
        //}
        //else
        //    console.log(stderr);
    });
}

function executeExeFile_day(filePath, ReqType, StartDate, EndDate, res)
{
    var {execFile} = require('child_process');

    // GetDashBoardData 파일 실행
    const child = execFile(filePath, [ReqType, StartDate, EndDate], {maxBuffer: 1024 * 5000}, (error, stdout, stderr) => {
        if( error )
        {
            console.log(stderr);
            throw error;
        }

        console.log(stdout);

        // 에러가 없음 => 정상
        //if( stderr == null || stderr == '' )
        //{            
            var filePath;
            if(ReqType == "du")
            {
                console.log(ReqType);
                filePath = './data/dailyCountByCameraDur.json';
                readJsonFile(filePath, res);
            }
            else if(ReqType == "dw")
            {
                console.log(ReqType);
                filePath = './data/dailyCountByEveryHourDate1.json';
                readJsonFile(filePath, res);
                //filePath = './data/dailyCountByCameraDate2.json';
            }
        //}
       //else
        //{
        //    console.log(stderr);
        //}
            
    });
}


// 생성된 JSON 파일을 읽는다
function readJsonFile(filePath, res)
{
    // 생성된 json파일 읽기
    var readFile = require('fs');
    readFile.readFile(filePath, 'utf8', function(readError, readData) {
        res.send(readData);
    });
}

