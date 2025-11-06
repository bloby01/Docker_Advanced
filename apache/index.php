<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Serveur Apache/PHP - Docker Advanced</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 {
            color: #667eea;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }
        .info-box {
            background: #f7f7f7;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin: 15px 0;
            border-radius: 5px;
        }
        .info-label {
            font-weight: bold;
            color: #667eea;
            display: inline-block;
            width: 200px;
        }
        .info-value {
            color: #333;
        }
        .success {
            color: #28a745;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #667eea;
            color: white;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Serveur Apache/PHP - Docker Advanced</h1>

        <div class="info-box">
            <span class="success">✓ Serveur opérationnel !</span>
        </div>

        <h2>Informations du serveur</h2>

        <div class="info-box">
            <span class="info-label">IP du serveur:</span>
            <span class="info-value"><?php echo $_SERVER["SERVER_ADDR"]; ?></span>
        </div>

        <div class="info-box">
            <span class="info-label">Hostname:</span>
            <span class="info-value"><?php echo gethostname(); ?></span>
        </div>

        <div class="info-box">
            <span class="info-label">Serveur Web:</span>
            <span class="info-value"><?php echo $_SERVER["SERVER_SOFTWARE"]; ?></span>
        </div>

        <div class="info-box">
            <span class="info-label">Version PHP:</span>
            <span class="info-value"><?php echo phpversion(); ?></span>
        </div>

        <div class="info-box">
            <span class="info-label">Adresse client:</span>
            <span class="info-value"><?php echo $_SERVER["REMOTE_ADDR"]; ?></span>
        </div>

        <div class="info-box">
            <span class="info-label">User Agent:</span>
            <span class="info-value"><?php echo $_SERVER["HTTP_USER_AGENT"]; ?></span>
        </div>

        <div class="info-box">
            <span class="info-label">Méthode de requête:</span>
            <span class="info-value"><?php echo $_SERVER["REQUEST_METHOD"]; ?></span>
        </div>

        <div class="info-box">
            <span class="info-label">Heure du serveur:</span>
            <span class="info-value"><?php echo date("Y-m-d H:i:s"); ?></span>
        </div>

        <h2>Extensions PHP chargées</h2>
        <table>
            <thead>
                <tr>
                    <th>Extension</th>
                    <th>Statut</th>
                </tr>
            </thead>
            <tbody>
                <?php
                $extensions = ['curl', 'json', 'mbstring', 'opcache', 'mysqli', 'pdo', 'gd', 'xml'];
                foreach ($extensions as $ext) {
                    $loaded = extension_loaded($ext);
                    echo "<tr>";
                    echo "<td>$ext</td>";
                    echo "<td>" . ($loaded ? "<span style='color: green;'>✓ Chargée</span>" : "<span style='color: red;'>✗ Non chargée</span>") . "</td>";
                    echo "</tr>";
                }
                ?>
            </tbody>
        </table>

        <h2>Variables d'environnement Docker</h2>
        <table>
            <thead>
                <tr>
                    <th>Variable</th>
                    <th>Valeur</th>
                </tr>
            </thead>
            <tbody>
                <?php
                $docker_vars = ['HOSTNAME', 'PATH', 'HOME'];
                foreach ($docker_vars as $var) {
                    $value = getenv($var);
                    if ($value !== false) {
                        echo "<tr>";
                        echo "<td>$var</td>";
                        echo "<td>" . htmlspecialchars($value) . "</td>";
                        echo "</tr>";
                    }
                }
                ?>
            </tbody>
        </table>
    </div>
</body>
</html>
