import 'package:shared_preferences/shared_preferences.dart';

class Config {
    static const String defaultHost = 'origine-s.onrender.com';
    static const int defaultPort = 443;

    static Future<String> getBaseUrl() async {
        final prefs = await SharedPreferences.getInstance();
        final host = prefs.getString('host') ?? defaultHost;
        final port = prefs.getInt('port') ?? defaultPort;
        final isCloud = host.contains('.onrender.com') || host.contains('railway.app') || host.contains('up.railway');
        if (isCloud) return 'https://$host';
        return 'http://$host:$port';
    }

    static Future<String> getWsUrl() async {
        final prefs = await SharedPreferences.getInstance();
        final host = prefs.getString('host') ?? defaultHost;
        final port = prefs.getInt('port') ?? defaultPort;
        final isCloud = host.contains('.onrender.com') || host.contains('railway.app') || host.contains('up.railway');
        if (isCloud) return 'wss://$host';
        return 'ws://$host:$port';
    }

    static Future<void> save(String host, int port) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('host', host);
        await prefs.setInt('port', port);
    }
}