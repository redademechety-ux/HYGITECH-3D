import React from 'react';
import { Phone, Mail, MapPin, Clock, Shield } from 'lucide-react';

export const Footer = () => {
  const currentYear = new Date().getFullYear();

  const scrollToSection = (sectionId) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <footer className="bg-gray-900 text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Informations entreprise */}
          <div className="space-y-4">
            <div className="flex items-center space-x-2">
              <div className="w-10 h-10 bg-gradient-to-r from-emerald-600 to-teal-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold">H3D</span>
              </div>
              <div>
                <h3 className="text-lg font-bold">HYGITECH-3D</h3>
                <p className="text-sm text-gray-400">Solutions d'hygiène professionnelles</p>
              </div>
            </div>
            <p className="text-gray-300 text-sm leading-relaxed">
              Spécialistes en désinfection, désinsectisation et dératisation. 
              Nous intervenons rapidement dans toute l'Île-de-France pour 
              résoudre vos problèmes d'hygiène.
            </p>
            <div className="flex items-center space-x-2">
              <Shield className="w-4 h-4 text-emerald-400" />
              <span className="text-sm text-gray-300">Produits certifiés & respectueux</span>
            </div>
          </div>

          {/* Services */}
          <div>
            <h4 className="text-lg font-semibold mb-4">Nos Services</h4>
            <ul className="space-y-3 text-sm">
              <li>
                <button
                  onClick={() => scrollToSection('services')}
                  className="text-gray-300 hover:text-emerald-400 transition-colors"
                >
                  Désinfection
                </button>
              </li>
              <li>
                <button
                  onClick={() => scrollToSection('services')}
                  className="text-gray-300 hover:text-emerald-400 transition-colors"
                >
                  Désinsectisation
                </button>
              </li>
              <li>
                <button
                  onClick={() => scrollToSection('services')}
                  className="text-gray-300 hover:text-emerald-400 transition-colors"
                >
                  Dératisation
                </button>
              </li>
              <li>
                <button
                  onClick={() => scrollToSection('services')}
                  className="text-gray-300 hover:text-emerald-400 transition-colors"
                >
                  Nettoyage fin de chantier
                </button>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h4 className="text-lg font-semibold mb-4">Contact</h4>
            <ul className="space-y-3 text-sm">
              <li className="flex items-center space-x-2">
                <Phone className="w-4 h-4 text-emerald-400" />
                <div>
                  <a href="tel:0668062970" className="text-gray-300 hover:text-emerald-400 transition-colors block">
                    06 68 06 29 70
                  </a>
                  <a href="tel:0181892886" className="text-gray-300 hover:text-emerald-400 transition-colors block">
                    01 81 89 28 86
                  </a>
                </div>
              </li>
              <li className="flex items-center space-x-2">
                <Mail className="w-4 h-4 text-emerald-400" />
                <a href="mailto:contact@hygitech-3d.com" className="text-gray-300 hover:text-emerald-400 transition-colors">
                  contact@hygitech-3d.com
                </a>
              </li>
              <li className="flex items-start space-x-2">
                <MapPin className="w-4 h-4 text-emerald-400 mt-0.5" />
                <div className="text-gray-300">
                  <p>122 Boulevard Gabriel Péri</p>
                  <p>92240 MALAKOFF</p>
                </div>
              </li>
            </ul>
          </div>

          {/* Zone d'intervention */}
          <div>
            <h4 className="text-lg font-semibold mb-4">Zone d'Intervention</h4>
            <div className="space-y-3 text-sm">
              <div className="flex items-center space-x-2">
                <Clock className="w-4 h-4 text-emerald-400" />
                <span className="text-gray-300">Intervention 24-48h</span>
              </div>
              <div className="text-gray-300">
                <p className="font-medium mb-2">Île-de-France :</p>
                <ul className="space-y-1 text-xs">
                  <li>• Paris (75)</li>
                  <li>• Hauts-de-Seine (92)</li>
                  <li>• Seine-Saint-Denis (93)</li>
                  <li>• Val-de-Marne (94)</li>
                  <li>• Seine-et-Marne (77)</li>
                  <li>• Yvelines (78)</li>
                  <li>• Essonne (91)</li>
                  <li>• Val-d'Oise (95)</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        {/* Barre de navigation */}
        <div className="border-t border-gray-800 mt-8 pt-8">
          <div className="flex flex-col md:flex-row justify-between items-center space-y-4 md:space-y-0">
            <nav className="flex flex-wrap justify-center md:justify-start gap-6 text-sm">
              <button
                onClick={() => scrollToSection('services')}
                className="text-gray-300 hover:text-emerald-400 transition-colors"
              >
                Services
              </button>
              <button
                onClick={() => scrollToSection('tarifs')}
                className="text-gray-300 hover:text-emerald-400 transition-colors"
              >
                Tarifs
              </button>
              <button
                onClick={() => scrollToSection('contact')}
                className="text-gray-300 hover:text-emerald-400 transition-colors"
              >
                Contact
              </button>
              <button
                onClick={() => scrollToSection('contact')}
                className="text-gray-300 hover:text-emerald-400 transition-colors"
              >
                Devis gratuit
              </button>
            </nav>
            
            <div className="text-sm text-gray-400">
              © {currentYear} HYGITECH-3D. Tous droits réservés.
            </div>
          </div>
        </div>

        {/* SEO Keywords footer (hidden) */}
        <div className="hidden">
          désinfection désinsectisation dératisation Île-de-France Paris Malakoff
          entreprise hygiène professionnelle rongeurs punaises cafards fourmis
          nettoyage chantier intervention rapide devis gratuit
        </div>
      </div>
    </footer>
  );
};