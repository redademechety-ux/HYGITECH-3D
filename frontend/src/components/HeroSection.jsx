import React from 'react';
import { Shield, Clock, CheckCircle, Star } from 'lucide-react';
import { Button } from './ui/button';

export const HeroSection = () => {
  const scrollToContact = () => {
    const element = document.getElementById('contact');
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section className="relative min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-50 to-emerald-50 pt-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Contenu principal */}
          <div className="space-y-8">
            <div className="space-y-4">
              <div className="inline-flex items-center px-4 py-2 bg-emerald-100 text-emerald-800 rounded-full text-sm font-medium">
                <Shield className="w-4 h-4 mr-2" />
                Experts certifiés en Île-de-France
              </div>
              
              <h1 className="text-4xl lg:text-6xl font-bold text-gray-900 leading-tight">
                <span className="text-emerald-600">Désinfection</span>,<br />
                <span className="text-teal-600">Désinsectisation</span> &<br />
                <span className="text-slate-600">Dératisation</span>
              </h1>
              
              <p className="text-xl text-gray-600 leading-relaxed">
                Solutions professionnelles d'hygiène pour entreprises et particuliers. 
                Intervention rapide et efficace dans toute l'Île-de-France.
              </p>
            </div>

            {/* Points clés */}
            <div className="grid sm:grid-cols-2 gap-4">
              <div className="flex items-center space-x-3">
                <CheckCircle className="w-5 h-5 text-emerald-600 flex-shrink-0" />
                <span className="text-gray-700">Intervention dès 99€ TTC</span>
              </div>
              <div className="flex items-center space-x-3">
                <Clock className="w-5 h-5 text-emerald-600 flex-shrink-0" />
                <span className="text-gray-700">Intervention rapide</span>
              </div>
              <div className="flex items-center space-x-3">
                <Shield className="w-5 h-5 text-emerald-600 flex-shrink-0" />
                <span className="text-gray-700">Produits certifiés</span>
              </div>
              <div className="flex items-center space-x-3">
                <Star className="w-5 h-5 text-emerald-600 flex-shrink-0" />
                <span className="text-gray-700">Devis gratuit</span>
              </div>
            </div>

            {/* CTA */}
            <div className="flex flex-col sm:flex-row gap-4">
              <Button
                onClick={scrollToContact}
                size="lg"
                className="bg-emerald-600 hover:bg-emerald-700 text-white px-8 py-4 text-lg"
              >
                Obtenir un devis gratuit
              </Button>
              <Button
                variant="outline"
                size="lg"
                className="border-emerald-600 text-emerald-600 hover:bg-emerald-50 px-8 py-4 text-lg"
                onClick={() => window.open('https://wa.me/33668062970', '_blank')}
              >
                WhatsApp
              </Button>
            </div>

            {/* Confiance */}
            <div className="pt-8 border-t border-gray-200">
              <p className="text-sm text-gray-500 mb-4">Ils nous font confiance :</p>
              <div className="flex items-center space-x-8 text-gray-400">
                <span className="font-semibold">Particuliers</span>
                <span className="font-semibold">Entreprises</span>
                <span className="font-semibold">Mairies</span>
                <span className="font-semibold">Commerces</span>
              </div>
            </div>
          </div>

          {/* Image/Illustration côté droit */}
          <div className="relative">
            <div className="aspect-square bg-gradient-to-br from-emerald-100 to-teal-100 rounded-3xl p-8 flex items-center justify-center">
              <div className="text-center space-y-6">
                <div className="w-32 h-32 bg-white rounded-full flex items-center justify-center mx-auto shadow-lg">
                  <Shield className="w-16 h-16 text-emerald-600" />
                </div>
                <div className="space-y-2">
                  <h3 className="text-2xl font-bold text-gray-900">Protection</h3>
                  <p className="text-gray-600">Solutions adaptées à votre environnement</p>
                </div>
              </div>
            </div>
            
            {/* Éléments décoratifs */}
            <div className="absolute -top-4 -right-4 w-24 h-24 bg-emerald-200 rounded-full opacity-20"></div>
            <div className="absolute -bottom-4 -left-4 w-32 h-32 bg-teal-200 rounded-full opacity-20"></div>
          </div>
        </div>
      </div>
    </section>
  );
};