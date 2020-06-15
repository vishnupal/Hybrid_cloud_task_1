<!DOCTYPE html>
<html lang='en'>
<head>
<title>Test Page</title>
    </head>
    <body>
        <h1>Vishnupl</h1>
<?php

      
$myfile = fopen("cloudfrount.txt", "r") or die("Unable to open file!");

$a =fread($myfile,filesize("cloudfrount.txt"));
echo " <img src='$a/images/img1.jpg' /> ";
echo "<img src='http://$a/images/img1.jpg' alt='Girl in a jacket' style='width:50%;height:60%'/>";
echo "";
fclose($myfile);
 ?>
</body>
</html>
