import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onBackToLogin;
  const RegisterPage({required this.onBackToLogin, Key? key}) : super(key: key);
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final k = GlobalKey<FormState>();
  final u = TextEditingController();
  final e = TextEditingController();
  final f = TextEditingController();
  final l = TextEditingController();
  final p = TextEditingController();
  final c = TextEditingController();
  final auth = AuthController();

  double s = 0;
  Map<String, bool> chk = {'len':false,'upper':false,'lower':false,'num':false,'special':false};
  bool loading = false;

  void check(String x){
    final a = x.length>=8;
    final b = RegExp(r'[A-Z]').hasMatch(x);
    final c = RegExp(r'[a-z]').hasMatch(x);
    final d = RegExp(r'[0-9]').hasMatch(x);
    final e = RegExp(r'[^A-Za-z0-9]').hasMatch(x);
    setState((){chk['len']=a;chk['upper']=b;chk['lower']=c;chk['num']=d;chk['special']=e;s=[a,b,c,d,e].where((v)=>v).length/5;});
  }

  Future<void> submit() async {
    if(!k.currentState!.validate()) return;
    setState(()=>loading=true);
    final err = await auth.register(
      username: u.text.trim(),
      email: e.text.trim(),
      password: p.text,
      firstName: f.text.trim(),
      lastName: l.text.trim(),
    );
    setState(()=>loading=false);
    if(err!=null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));return;}
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created')));
    // Navigate to onboarding for new users
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primary.withOpacity(.15), theme.secondary.withOpacity(.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
          )
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.surface.withOpacity(.85),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: theme.primary.withOpacity(.12), blurRadius: 20, offset: const Offset(0,10))
                ]
              ),
              width: 420,
              child: Form(
                key: k,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Create your account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 18),
                    TextFormField(controller: u, decoration: const InputDecoration(labelText:"Username"), validator:(v)=>v==null||v.isEmpty?'Required':null),
                    TextFormField(controller: e, decoration: const InputDecoration(labelText:"Email"), keyboardType: TextInputType.emailAddress,
                      validator:(v){if(v==null||v.isEmpty)return'Required';if(!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))return'Invalid';return null;}),
                    Row(children:[
                      Expanded(child:TextFormField(controller:f,decoration:const InputDecoration(labelText:"First Name"),validator:(v)=>v==null||v.isEmpty?'Required':null)),
                      const SizedBox(width:12),
                      Expanded(child:TextFormField(controller:l,decoration:const InputDecoration(labelText:"Last Name"),validator:(v)=>v==null||v.isEmpty?'Required':null)),
                    ]),
                    TextFormField(controller:p,decoration:const InputDecoration(labelText:"Password"),obscureText:true,onChanged:check,
                      validator:(v){if(v==null||v.isEmpty)return'Required';if(s<1)return'Password too weak';return null;}),
                    const SizedBox(height:10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds:300),
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: s,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: s<0.4?Colors.red:s<1?Colors.orange:Colors.green
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height:10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children:[
                        _tag("8+ chars", chk['len']!),
                        _tag("Uppercase", chk['upper']!),
                        _tag("Lowercase", chk['lower']!),
                        _tag("Number", chk['num']!),
                        _tag("Special", chk['special']!),
                      ],
                    ),
                    const SizedBox(height:16),
                    TextFormField(controller:c,decoration:const InputDecoration(labelText:"Confirm Password"),obscureText:true,
                      validator:(v)=>v!=p.text?'Does not match':null),
                    const SizedBox(height:28),
                    loading?const Center(child:CircularProgressIndicator()):FilledButton(
                      onPressed: submit,
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text("Register"),
                    ),
                    TextButton(onPressed: widget.onBackToLogin, child: const Text("Back to login")),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String t, bool ok){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: ok?Colors.green.withOpacity(.15):Colors.grey.withOpacity(.15),
      ),
      child: Text(t, style: TextStyle(color: ok?Colors.green:Colors.grey[700], fontSize:13)),
    );
  }
}
