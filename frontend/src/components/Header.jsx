import React, { useState } from 'react';
import { Menu, X, Phone, MapPin } from 'lucide-react';
import { Button } from './ui/button';

export const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const scrollToSection = (sectionId) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
      setIsMenuOpen(false);
    }
  };

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          {/* Logo */}
          <div className="flex items-center space-x-2">
            <div className="w-12 h-12 bg-gradient-to-r from-emerald-600 to-teal-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-lg">H3D</span>
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">HYGITECH-3D</h1>
              <p className="text-xs text-emerald-600">Solutions d'hygiène professionnelles</p>
            </div>
          </div>

          {/* Contact rapide desktop */}
          <div className="hidden lg:flex items-center space-x-6">
            <div className="flex items-center space-x-2 text-sm text-gray-600">
              <Phone className="w-4 h-4 text-emerald-600" />
              <span>06 68 06 29 70</span>
            </div>
            <div className="flex items-center space-x-2 text-sm text-gray-600">
              <MapPin className="w-4 h-4 text-emerald-600" />
              <span>Île-de-France</span>
            </div>
          </div>

          {/* Navigation desktop */}
          <nav className="hidden md:flex items-center space-x-8">
            <button
              onClick={() => scrollToSection('services')}
              className="text-gray-700 hover:text-emerald-600 transition-colors"
            >
              Services
            </button>
            <button
              onClick={() => scrollToSection('zones')}
              className="text-gray-700 hover:text-emerald-600 transition-colors"
            >
              Zones d'intervention
            </button>
            <button
              onClick={() => scrollToSection('tarifs')}
              className="text-gray-700 hover:text-emerald-600 transition-colors"
            >
              Tarifs
            </button>
            <button
              onClick={() => scrollToSection('contact')}
              className="text-gray-700 hover:text-emerald-600 transition-colors"
            >
              Contact
            </button>
            <Button
              onClick={() => scrollToSection('contact')}
              className="bg-emerald-600 hover:bg-emerald-700 text-white px-6 py-2"
            >
              Devis gratuit
            </Button>
          </nav>

          {/* Menu mobile */}
          <button
            className="md:hidden"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Menu mobile ouvert */}
        {isMenuOpen && (
          <div className="md:hidden pb-4 border-t border-gray-200 mt-4">
            <nav className="flex flex-col space-y-3 pt-4">
              <button
                onClick={() => scrollToSection('services')}
                className="text-left text-gray-700 hover:text-emerald-600 transition-colors py-2"
              >
                Services
              </button>
              <button
                onClick={() => scrollToSection('zones')}
                className="text-left text-gray-700 hover:text-emerald-600 transition-colors py-2"
              >
                Zones d'intervention
              </button>
              <button
                onClick={() => scrollToSection('tarifs')}
                className="text-left text-gray-700 hover:text-emerald-600 transition-colors py-2"
              >
                Tarifs
              </button>
              <button
                onClick={() => scrollToSection('contact')}
                className="text-left text-gray-700 hover:text-emerald-600 transition-colors py-2"
              >
                Contact
              </button>
              <Button
                onClick={() => scrollToSection('contact')}
                className="bg-emerald-600 hover:bg-emerald-700 text-white w-full mt-4"
              >
                Devis gratuit
              </Button>
            </nav>
          </div>
        )}
      </div>
    </header>
  );
};