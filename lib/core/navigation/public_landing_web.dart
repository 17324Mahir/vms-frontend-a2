import 'package:web/web.dart' as web;

bool get isWebWorkspace =>
    web.window.location.pathname.endsWith('/workspace.html');

void openPublicLanding() {
  web.window.location.assign('/');
}
