const http = require('http');
const port = process.env.PORT || 3000;
const username = process.env.USER;
const password = process.env.PASSWORD;
const message = process.env.SECRET_MESSAGE;

const processRequest = (req, res) => {

   res.setHeader('Content-Type', 'text/plain; charset=utf-8');

    if(req.url === '/'){
        res.end('Hello World Test Deploy!!!!!');
    }else if(req.url === '/secure'){
        if(authenticate(req,res)){
            res.end(message);
        }
    }else if(req.url === '/about'){
        res.end('This is the about page.</p>');
    }
}

function authenticate(req,res){
    const authHeader = req.headers['authorization'];
    if(!authHeader){
        res.writeHead(401, {'WWW-Authenticate': 'Basic realm="Secure Area"'});
        res.end('Unauthorized');
        return false;
    }

    const base64Credentials = authHeader.split(' ')[1];
    const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
    const [inputUsername, inputPassword] = credentials.split(':');
    console.log(`Login attempt with username: ${username} and password: ${password}`);
    if(inputUsername !== username || inputPassword !== password){
        console.log(`Failed login attempt with username: ${inputUsername} and password: ${inputPassword}`);
        res.writeHead(401, {'WWW-Authenticate': 'Basic realm="Secure Area"'});
        res.end('Unauthorized');
        return false;
    }
    return true;
}

const server = http.createServer(processRequest);

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});