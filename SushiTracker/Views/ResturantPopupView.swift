//
//  ResturantPopupView.swift
//  SushiTracker
//
//  Created by Giulio Aterno on 07/09/23.
//

import SwiftUI
import CoreData
import MapKit

struct RestaurantPopupView: View {
    
    enum Field {
        case name, address
    }
    
    @ObservedObject var model: RestaurantModel
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedRating = 0
    @State private var showAlert = false
    
    @State private var restaurantName = ""
    @State private var restaurantAddress = ""
    
    @State private var restaurantLocation: CLLocationCoordinate2D?
    
    @FocusState private var focusField: Field?
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                HStack {
                    Text("Inserisci i dati")
                        .bold()
                        .padding(15)
                        .font(.title)
                    
                }
                
                
                VStack(alignment: .leading) {
                    Text("🍣 Nome")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .bold()
                    
                    TextField("", text: $restaurantName)
                        .padding(15)
                        .background(Color(.systemGray6))
                        .disableAutocorrection(true)
                        .submitLabel(.next)
                        .mask(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .focused($focusField, equals: .name)
                        .onSubmit {
                            focusField = .address
                        }
                        .shadow(radius: 10)
                }
                .padding(20)
                
                VStack(alignment: .leading) {
                    Text("📍 Indirizzo")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.black)
                    
                    TextField("", text: $restaurantAddress)
                        .padding(15)
                        .disableAutocorrection(true)
                        .background(Color(.systemGray6))
                        
                        .focused($focusField, equals: .address)
                        .mask(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .submitLabel(.done)
                        .onSubmit {
                            focusField = nil
                        }
                        .onChange(of: restaurantAddress) { newValue in
                            geocodeAddress()
                        }
                        .shadow(radius: 10)
                }
                .padding(20)

                HStack {
                        MapView(coordinate: $restaurantLocation)
                            .frame(height: 200)
                            .cornerRadius(10)
                            .padding(20)
                            .background(Color.clear)
                            .shadow(radius: 5)
                    
                }
                                
                Picker("Valutazione", selection: $selectedRating) {
                    ForEach(1..<6, id: \.self) { rating in
                        if selectedRating >= rating {
                            Image("star_filled")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                        } else {
                            Image("star_empty")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                HStack {
                    Button(action: {
                        if restaurantName.isEmpty || restaurantAddress.isEmpty {
                            showAlert = true
                        } else {
                            let rating = selectedRating
                            // Crea e salva un nuovo ristorante in Core Data
                            let newRestaurant = RestaurantItem(context: viewContext)
                            newRestaurant.name = restaurantName
                            newRestaurant.address = restaurantAddress
                            newRestaurant.rating = Int16(rating)
                            do {
                                try viewContext.save()
                                isPresented = false
                            } catch {
                                print("Errore durante il salvataggio: \(error)")
                            }
                        }
                    }) {
                        Text("Salva")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Annulla")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                Spacer()
            }
            .background(Color.yellow)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Errore"), message: Text("Inserisci entrambi i campi, quindi riprova"), dismissButton: .default(Text("OK")))
        }
        .onDisappear {
            restaurantName = ""
            restaurantAddress = ""
            selectedRating = 0
        }
    }
    
    func geocodeAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(restaurantAddress) { placemarks, error in
            if let placemark = placemarks?.first {
                if let location = placemark.location {
                    restaurantLocation = location.coordinate
                    
                    // Aggiorna la vista principale in modo che la mappa si aggiorni
                    DispatchQueue.main.async {
                        self.viewContext.refreshAllObjects()
                    }
                }
            } else {
                // Gestisci l'errore di geocodifica
                print("Errore durante la geocodifica: \(error?.localizedDescription ?? "Errore sconosciuto")")
            }
        }
    }
    
    struct RestaurantPopupView_Preview: PreviewProvider {
        static var previews: some View {
            RestaurantPopupView(model: RestaurantModel(), isPresented: .constant(true))
        }
    }
}