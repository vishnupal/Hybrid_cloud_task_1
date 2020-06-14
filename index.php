<!DOCTYPE html>
<html lang='en'>
<head>
<title>Test Page</title>
    </head>
    <body>
<?php
echo ' <img src="vimal.jpg" /> ';

      
$myfile = fopen("cloudfrount.txt", "r") or die("Unable to open file!");

$a =fread($myfile,filesize("cloudfrount.txt"));
echo " <img src='$a' /> ";
echo "<img src='$a' alt='Girl in a jacket' style='width:50%;height:60%'/>";
echo "";
fclose($myfile);
 ?>
</body>
</html>
