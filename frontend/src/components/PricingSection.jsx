import React from 'react';
import { Check, Phone, MapPin, Clock } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';

export const PricingSection = () => {
  const services = [
    {
      name: "Rongeurs",
      price: "250",
      unit: "€ HT",
      description: "Dératisation complète",
      features: [
        "Diagnostic complet",
        "Pose de pièges sécurisés", 
        "Bouchage des accès",
        "Suivi post-intervention"
      ]
    },
    {
      name: "Blattes",
      price: "180",
      unit: "€ HT", 
      description: "Désinsectisation ciblée",
      features: [
        "Traitement par pulvérisation",
        "Gel appât professionnel",
        "Zones de reproduction",
        "Garantie de résultat"
      ]
    },
    {
      name: "Fourmis",
      price: "130",
      unit: "€ TTC",
      description: "Élimination des colonies",
      features: [
        "Localisation des nids",
        "Traitement longue durée",
        "Barrière préventive", 
        "Conseils d'hygiène"
      ]
    },
    {
      name: "Punaises de lit",
      price: "200",
      unit: "€ HT",
      description: "Traitement spécialisé",
      features: [
        "Détection minutieuse",
        "Traitement thermique/chimique",
        "Plusieurs passages",
        "Accompagnement client"
      ],
      popular: true
    }
  ];

  const scrollToContact = () => {
    const element = document.getElementById('contact');
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section id="tarifs" className="py-20 bg-gradient-to-br from-slate-50 to-emerald-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* En-tête */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Nos Tarifs Transparents
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Des prix clairs et compétitifs pour tous vos besoins d'hygiène. 
            Devis gratuit et sans engagement.
          </p>
        </div>

        {/* Grille des tarifs */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          {services.map((service, index) => (
            <Card 
              key={index} 
              className={`relative hover:shadow-lg transition-all duration-300 hover:-translate-y-1 ${
                service.popular ? 'ring-2 ring-emerald-500 shadow-lg' : ''
              }`}
            >
              {service.popular && (
                <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                  <span className="bg-emerald-500 text-white px-4 py-1 rounded-full text-sm font-medium">
                    Plus demandé
                  </span>
                </div>
              )}
              
              <CardHeader className="text-center pb-4">
                <CardTitle className="text-xl text-gray-900 mb-2">{service.name}</CardTitle>
                <CardDescription className="text-gray-600 mb-4">
                  {service.description}
                </CardDescription>
                <div className="text-center">
                  <span className="text-3xl font-bold text-emerald-600">
                    À partir de {service.price}
                  </span>
                  <span className="text-gray-500 ml-1">{service.unit}</span>
                </div>
              </CardHeader>
              
              <CardContent>
                <ul className="space-y-3 mb-6">
                  {service.features.map((feature, idx) => (
                    <li key={idx} className="flex items-center text-sm text-gray-600">
                      <Check className="w-4 h-4 text-emerald-600 mr-3 flex-shrink-0" />
                      {feature}
                    </li>
                  ))}
                </ul>
                
                <Button
                  onClick={scrollToContact}
                  variant={service.popular ? "default" : "outline"}
                  className={`w-full ${
                    service.popular 
                      ? 'bg-emerald-600 hover:bg-emerald-700 text-white' 
                      : 'border-emerald-600 text-emerald-600 hover:bg-emerald-50'
                  }`}
                >
                  Demander un devis
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Informations importantes */}
        <div className="grid md:grid-cols-3 gap-6 mb-12">
          <div className="bg-white rounded-lg p-6 text-center shadow-sm">
            <Clock className="w-8 h-8 text-emerald-600 mx-auto mb-4" />
            <h4 className="font-semibold text-gray-900 mb-2">Intervention Rapide</h4>
            <p className="text-sm text-gray-600">
              Délai d'intervention 24-48h selon urgence
            </p>
          </div>
          
          <div className="bg-white rounded-lg p-6 text-center shadow-sm">
            <MapPin className="w-8 h-8 text-emerald-600 mx-auto mb-4" />
            <h4 className="font-semibold text-gray-900 mb-2">Frais de Déplacement</h4>
            <p className="text-sm text-gray-600">
              Variables selon votre zone en Île-de-France
            </p>
          </div>
          
          <div className="bg-white rounded-lg p-6 text-center shadow-sm">
            <Phone className="w-8 h-8 text-emerald-600 mx-auto mb-4" />
            <h4 className="font-semibold text-gray-900 mb-2">Devis Gratuit</h4>
            <p className="text-sm text-gray-600">
              Évaluation et devis sans engagement
            </p>
          </div>
        </div>

        {/* Nettoyage fin de chantier */}
        <div className="bg-white rounded-2xl p-8 shadow-sm">
          <div className="text-center mb-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">
              Nettoyage Fin de Chantier
            </h3>
            <p className="text-gray-600">
              Service spécialisé pour la remise en état après travaux de construction
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 gap-8 items-center">
            <div>
              <ul className="space-y-3">
                <li className="flex items-center text-gray-700">
                  <Check className="w-5 h-5 text-emerald-600 mr-3" />
                  Évacuation des gravats et déchets
                </li>
                <li className="flex items-center text-gray-700">
                  <Check className="w-5 h-5 text-emerald-600 mr-3" />
                  Nettoyage approfondi des poussières
                </li>
                <li className="flex items-center text-gray-700">
                  <Check className="w-5 h-5 text-emerald-600 mr-3" />
                  Remise en état complète
                </li>
                <li className="flex items-center text-gray-700">
                  <Check className="w-5 h-5 text-emerald-600 mr-3" />
                  Livraison clé en main
                </li>
              </ul>
            </div>
            
            <div className="text-center">
              <p className="text-sm text-gray-600 mb-4">
                Tarif personnalisé selon surface et état
              </p>
              <Button
                onClick={scrollToContact}
                size="lg"
                className="bg-emerald-600 hover:bg-emerald-700 text-white px-8"
              >
                Demander un devis personnalisé
              </Button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};