import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PayPalWebView extends StatefulWidget {
  final String url;
  final String orderId;
  final int spaceId;
final DateTime startTime;
final DateTime endTime;
final List<Map<String, dynamic>> amenities;

  const PayPalWebView({
      super.key,
  required this.url,
  required this.orderId,
  required this.spaceId,
  required this.startTime,
  required this.endTime,
  required this.amenities,
  });

  @override
  State<PayPalWebView> createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
        onNavigationRequest: (request) async {
  final url = request.url;


  if (url.contains("meetspace://paypal/success")) {

    final auth = context.read<AuthProvider>();

  await auth.paymentService.capturePaypalOrder(
  orderId: widget.orderId,
  spaceId: widget.spaceId,
  startTime: widget.startTime,
  endTime: widget.endTime,
  amenities: widget.amenities,
);

    if (!mounted) return NavigationDecision.prevent;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment successful")),
    );

    Navigator.popUntil(context, (r) => r.isFirst);

    return NavigationDecision.prevent;
  }

  if (url.contains("meetspace://paypal/cancel")) {

    Navigator.pop(context);
    return NavigationDecision.prevent;
  }

  return NavigationDecision.navigate;
},
          onPageFinished: (_) {
            setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}