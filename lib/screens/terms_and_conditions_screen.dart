import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido a Venered',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Estos términos y condiciones rigen el uso de la aplicación móvil Venered. Al acceder o utilizar la aplicación, aceptas estar sujeto a estos términos y condiciones.',
            ),
            SizedBox(height: 20),
            Text(
              '1. Uso de la Aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Venered es una aplicación de red social que permite a los usuarios compartir publicaciones, seguir a otros y interactuar con contenido visual. Debes tener al menos 13 años para usar esta aplicación. Eres responsable de mantener la confidencialidad de tu cuenta y contraseña.',
            ),
            SizedBox(height: 20),
            Text(
              '2. Contenido del Usuario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Eres el único responsable del contenido que publicas en Venered. No debes publicar contenido ilegal, ofensivo, difamatorio o que infrinja los derechos de terceros. Nos reservamos el derecho de eliminar cualquier contenido que consideremos inapropiado.',
            ),
            SizedBox(height: 20),
            Text(
              '3. Privacidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Tu privacidad es importante para nosotros. Consulta nuestra Política de Privacidad para obtener información sobre cómo recopilamos, usamos y protegemos tus datos.',
            ),
            SizedBox(height: 20),
            Text(
              '4. Terminación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Nos reservamos el derecho de suspender o terminar tu acceso a la aplicación en cualquier momento y por cualquier motivo, sin previo aviso.',
            ),
            SizedBox(height: 20),
            Text(
              '5. Cambios en los Términos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Podemos modificar estos términos y condiciones en cualquier momento. Te notificaremos sobre cualquier cambio publicando los nuevos términos en la aplicación. Tu uso continuado de la aplicación después de dichas modificaciones constituirá tu aceptación de los términos revisados.',
            ),
            SizedBox(height: 20),
            Text(
              '6. Contacto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Si tienes alguna pregunta sobre estos términos y condiciones, contáctanos a través de [correo electrónico de contacto].',
            ),
            SizedBox(height: 20),
            Text(
              'Fecha de última actualización: 24 de febrero de 2026',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
