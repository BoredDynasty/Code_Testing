    <!DOCTYPE HTML>

    <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="description" content="SchoolZone">
            <meta name="author" content="Edmonton Public Schools">
            <head profile="http://www.w3.org/2005/10/profile">

            <link rel="apple-touch-icon" href="/images/apple-touch-icon.png" sizes="180x180">
            <link rel="icon" type="image/png" href="/images/favicon-32x32.png" sizes="32x32" />
            <link rel="icon" type="image/png" href="/images/favicon-16x16.png" sizes="16x16" />

            
            <title>SchoolZone - Sign In</title>
            <link rel="stylesheet" type="text/css" href="/css/libs/fonts.googleapis/familyFiraSans.css">
            <link rel="stylesheet" type="text/css" href="/css/libs/fonts.googleapis/familyLato.css">
            <link rel="stylesheet" type="text/css" href="/css/schoolzone-bootstrap.css">
            <link rel="stylesheet" type="text/css" href="/css/custom.css"> 
            <script src="/js/libs/jquery-3.1.1.min.js" type="text/javascript"></script>
            <script src="/js/libs/bootstrap.min.js" type="text/javascript"></script>
            
        </head>

        <body>
            
                <span id="server_name" class="hidden-print">schoolzone-03</span>
                
			<nav class="navbar navbar-inverse navbar-fixed-top">
				<div class="container">
					
					<div class="navbar-header">
						
						<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#top-navbar" aria-expanded="false" aria-controls="navbar">
							<span class="sr-only">Toggle navigation</span>
							<span style="color: white;" class="glyphicon glyphicon-menu-hamburger" aria-hidden="true"></span>
						</button>

						
						<a class="navbar-brand" href="https://schoolzone.epsb.ca">SchoolZone</a>
					</div>

					
					<div id="top-navbar" class="navbar-collapse collapse">
						<ul class="nav navbar-nav">
							
							<li class="dropdown">
								<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Help <span class="caret"></span></a>
								<ul class="dropdown-menu">
									<li><a href="https://sites.google.com/share.epsb.ca/schoolzone-external-help/home" rel="noopener" target="_blank">Help</a></li>
									<li><a href="https://sites.google.com/share.epsb.ca/schoolzone-external-help/frequently-asked-questions/how-do-i-login" rel="noopener" target="_blank">Can't sign in?</a></li>
									<li><a href="https://sites.google.com/share.epsb.ca/schoolzone-external-help/home/terms-of-use" rel="noopener" target="_blank">Terms of Use</a></li>
									
								</ul>
							</li>
						</ul>
					</div>
				</div>
			</nav>
		

            
            <div id="mainDiv">
                <div class="container" style="margin-bottom: 40px;">



	<script type="text/javascript">
		$(document).ready(function(){
			$("#loginForm").submit(function(){
				$("input").attr("readonly", true);
				$("input[type=submit]").attr("disabled", "disabled");
				$("a").unbind("click").click(function(e) {
					e.preventDefault();
				});
			});
		});
	</script>

	<div class="container">
		<h1 style="color: black; font-weight: normal;">Hurry up and Sign in already!</h1>
		<div class="row">
			
			<div class="col-md-4 login-div-nopad">
				<div class="panel panel-login" id="loginPanel">
					<div class="panel-body panel-body-login">
						
							<form class="form-horizontal" role="form" action="/cf/login.cfm" method="POST" id="loginForm">
								<div class="form-group">
									<label for="userID" class="col-sm-3 control-label">Username</label>
									<div class="col-sm-9">
										<input pattern="[\w.-]{2,}" required title="Please enter only numbers and letters" type="text" autocomplete="username" class="form-control" id="userID" name="userID" required="true" autofocus>
									</div>
								</div>
								<div class="form-group">
									<label for="loginPassword" class="col-sm-3 control-label">Password</label>
									<div class="col-sm-9">
										<input type="password" autocomplete="current-password" class="form-control" id="loginPassword" name="loginPassword" required="true">
									</div>
								</div>
								<div class="form-group last">
									<div class="col-sm-offset-3 col-sm-9">
										<input type="hidden" name="bSubmitForm" value="1">
										<input type="submit" name="btnSignIn" class="btn btn-success col-xs-12" value="Sign in">
									</div>
								</div>
							</form>
						
					</div>
					<div class="text-center" style="margin: 0 2px; padding: 0; display: flex; justify-content: space-around;">
						
							<a href="https://sites.google.com/share.epsb.ca/schoolzone-external-help/home/terms-of-use" rel="noopener" target="_blank">Terms of Use</a> |
							<a href="/cf/help/hint.cfm" rel="noopener">Reset Password</a> |
							<a href="https://www.epsb.ca" rel="noopener" target="_blank">epsb.ca</a>
						
					</div>
				</div>
			</div>

			
			<div class="col-md-8 login-div-nopad">
				<div class="panel panel-login" id="loginMsgPanel" style="border-width: 0 0 0 4px; border-color: orange; padding-left: 25px;">
					<div class="panel-body">
						<p><img src="/images/epsb-wordmark-districtblue.svg" alt="Edmonton Public School Boards Logo" style="height: 32px;" /></p>
						<br>
						<p>
							
							
							If you don't have your SchoolZone login information, or login information for your child, you may want to contact your child's school for assistance.
<br><br>

Whether you're an Edmonton Public Schools parent, student or teacher, SchoolZone gives you secure access to "important" news and student information.

						</p>
					</div>
				</div>
			</div>
			</nav>
        </body>
    </html>

